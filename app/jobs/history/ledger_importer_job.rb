require 'bigdecimal'

#
# Takes the ledger header and transaction set of the requested sequence from the
# stellar_core database and imports them into the history database.
#
class History::LedgerImporterJob < ApplicationJob

  # To allow for updated importer code, we version every history_ledger imported into the horizon by recording the
  # constant below with the new record.
  #
  # IMPORTANT: bump this number up if you ever change the behavior of the importer, so that the reimport system
  # can detect the change and update older imported ledgers.
  VERSION = 5


  EMPTY_HASH            = "0" * 64
  DEFAULT_SIGNER_WEIGHT = 1

  def perform(ledger_sequence, rebuild_allowed=false)
    stellar_core_ledger, stellar_core_transactions = load_stellar_core_data(ledger_sequence)

    if stellar_core_ledger.blank?
      raise ActiveRecord::RecordNotFound,
        "Couldn't find ledger #{ledger_sequence}"
    end

    with_db(:history) do
      first_ledger = stellar_core_ledger.ledgerseq == 1

      create_master_history_account! if first_ledger

      History::Base.transaction do
        # ensure we've imported the previous header
        unless first_ledger
          History::Ledger.validate_previous_ledger_hash!(stellar_core_ledger.prevhash, stellar_core_ledger.ledgerseq)
        end

        # clear out any existing imported data for this ledger, allowing us to re-import the data if necessary
        found = History::Ledger.where(sequence: stellar_core_ledger.ledgerseq).first

        if found.present?
          return unless rebuild_allowed
          found.transactions.each(&:destroy)
          found.accounts.each(&:destroy)
          found.destroy
        end

        result = History::Ledger.create!({
          sequence:             stellar_core_ledger.ledgerseq,
          ledger_hash:          stellar_core_ledger.ledgerhash,
          previous_ledger_hash: (stellar_core_ledger.prevhash unless first_ledger),
          closed_at:            Time.at(stellar_core_ledger.closetime),
          transaction_count:    stellar_core_transactions.length,
          operation_count:      stellar_core_transactions.map(&:operation_count).sum,
          importer_version:     VERSION,
          total_coins:          stellar_core_ledger.total_coins,
          fee_pool:             stellar_core_ledger.fee_pool,
          base_fee:             stellar_core_ledger.base_fee,
          base_reserve:         stellar_core_ledger.base_reserve,
          max_tx_set_size:      stellar_core_ledger.max_tx_set_size,
        })

        stellar_core_transactions.each do |sctx|
          next unless sctx.success?

          htx   = import_history_transaction sctx
          haccs = import_history_accounts sctx
          hops  = import_history_operations sctx, htx
          heffs = import_history_effects sctx, hops
        end

        result
      end
    end
  end

  private

  def load_stellar_core_data(ledger_sequence)
    with_db(:stellar_core) do
      ledger = StellarCore::LedgerHeader.at_sequence(ledger_sequence)

      [ledger, (ledger.transactions.to_a if ledger)]
    end
  end

  def import_history_transaction(sctx)
    htx = History::Transaction.create!({
      transaction_hash:   sctx.txid,
      ledger_sequence:    sctx.ledgerseq,
      application_order:  sctx.txindex,
      account:            sctx.submitting_address,
      account_sequence:   sctx.submitting_sequence,
      fee_paid:           sctx.fee_paid,
      operation_count:    sctx.operations.size,
      tx_envelope:        sctx.txbody,
      tx_result:          sctx.txresult_without_pair,
      tx_meta:            sctx.txmeta,
      tx_fee_meta:        sctx.fee_meta.xdr,
      signatures:         sctx.signatures,
      time_bounds:        sctx.time_bounds,
      memo_type:          sctx.memo_type,
      memo:               sctx.memo,
    })

    sctx.participant_addresses.each do |addr|
      History::TransactionParticipant.create!({
        transaction_hash:  sctx.txid,
        account: addr
      })
    end

    htx
  end

  def import_history_accounts(sctx)
    haccs = []

    sctx.operations.each_with_index do |op, i|
      next unless op.body.type == Stellar::OperationType.create_account

      pop                 = op.body.value
      destination_pk      = pop.destination
      destination_address = Stellar::Convert.pk_to_address(destination_pk)
      id                  = TotalOrderId.make(sctx.ledgerseq, sctx.txindex, i+1)

      unless History::Account.where(address: destination_address).any?
        haccs << History::Account.create!(address: destination_address, id: id)
      end
    end

    haccs
  end

  def import_history_operations(sctx, htx)
    hops = []

    sctx.operations_with_results.each_with_index do |op_and_r, i|
      application_order = i + 1
      op, result = *op_and_r

      source_account = op.source_account || sctx.source_account
      source_address = Stellar::Convert.pk_to_address(source_account)
      participant_addresses = [source_address]

      hop = History::Operation.new({
        transaction_id:     htx.id,
        application_order:  application_order,
        type:               op.body.type.value,
        source_account:     source_address,
        details:            {},
      })


      case op.body.type
      when Stellar::OperationType.create_account
        op = op.body.create_account_op!
        participant_addresses << Stellar::Convert.pk_to_address(op.destination)

        hop.details = {
          "funder"           => Stellar::Convert.pk_to_address(source_account),
          "account"          => Stellar::Convert.pk_to_address(op.destination),
          "starting_balance" => as_amount(op.starting_balance),
        }
      when Stellar::OperationType.payment
        payment = op.body.payment_op!

        hop.details = {
          "from"   => Stellar::Convert.pk_to_address(source_account),
          "to"     => Stellar::Convert.pk_to_address(payment.destination),
          "amount" => as_amount(payment.amount),
        }
        hop.details.merge! asset_details(payment.asset)

        participant_addresses << hop.details["to"]

      when Stellar::OperationType.path_payment
        payment = op.body.path_payment_op!
        result = result.tr!.path_payment_result!

        hop.details = {
          "from"          => Stellar::Convert.pk_to_address(source_account),
          "to"            => Stellar::Convert.pk_to_address(payment.destination),
          "amount"        => as_amount(payment.dest_amount),
          "source_amount" => as_amount(result.send_amount),
          "source_max"    => as_amount(payment.send_max)
        }

        hop.details.merge! asset_details(payment.dest_asset)
        hop.details.merge! asset_details(payment.send_asset, "source_")
        hop.details["path"] = payment.path.map{|a| asset_details(a)}

        participant_addresses << hop.details["to"]
      when Stellar::OperationType.manage_offer
        offer = op.body.manage_offer_op!

        hop.details = {
          "offer_id" => offer.offer_id,
          "amount"   => as_amount(offer.amount),
          "price" => price_string(offer.price),
          "price_r"    => {
            "n" => offer.price.n,
            "d" => offer.price.d,
          },
        }

        hop.details.merge!(asset_details(offer.selling, "selling_"))
        hop.details.merge!(asset_details(offer.buying, "buying_"))
      when Stellar::OperationType.create_passive_offer
        offer = op.body.create_passive_offer_op!

        hop.details = {
          "amount"    => as_amount(offer.amount),
          "price" => price_string(offer.price),
          "price_r"     => {
            "n" => offer.price.n,
            "d" => offer.price.d,
          }
        }

        hop.details.merge!(asset_details(offer.selling, "selling_"))
        hop.details.merge!(asset_details(offer.buying, "buying_"))
      when Stellar::OperationType.set_options
        sop = op.body.set_options_op!
        hop.details = {}

        if sop.inflation_dest.present?
          hop.details["inflation_dest"] = Stellar::Convert.pk_to_address(sop.inflation_dest)
        end

        parsed = Stellar::AccountFlags.parse_mask(sop.set_flags || 0)
        if parsed.any?
          hop.details["set_flags"] = parsed.map(&:value)
          hop.details["set_flags_s"] = parsed.map(&:name)
        end

        parsed = Stellar::AccountFlags.parse_mask(sop.clear_flags || 0)
        if parsed.any?
          hop.details["clear_flags"] = parsed.map(&:value)
          hop.details["clear_flags_s"] = parsed.map(&:name)
        end

        if sop.master_weight.present?
          hop.details["master_key_weight"] = sop.master_weight
        end

        if sop.low_threshold.present?
          hop.details["low_threshold"]     = sop.low_threshold
        end

        if sop.med_threshold.present?
          hop.details["med_threshold"]  = sop.med_threshold
        end

        if sop.high_threshold.present?
          hop.details["high_threshold"]    = sop.high_threshold
        end

        if sop.home_domain.present?
          hop.details["home_domain"] = sop.home_domain
        end

        if sop.signer.present?
          hop.details.merge!({
            "signer_key"    => Stellar::Convert.pk_to_address(sop.signer.pub_key),
            "signer_weight" => sop.signer.weight,
          })
        end

      when Stellar::OperationType.change_trust
        ctop        = op.body.change_trust_op!
        asset    = ctop.line

        hop.details = {
          "trustor" => Stellar::Convert.pk_to_address(source_account),
          "limit"   => as_amount(ctop.limit),
        }
        hop.details.merge! asset_details(asset)
        hop.details["trustee"] = hop.details["asset_issuer"]

        if asset.type == Stellar::AssetType.asset_type_native
          raise "native asset in change_trust_op"
        end

      when Stellar::OperationType.allow_trust
        atop  = op.body.allow_trust_op!
        asset = atop.asset

        hop.details = {
          "trustee"         => Stellar::Convert.pk_to_address(source_account),
          "trustor"         => Stellar::Convert.pk_to_address(atop.trustor),
          "authorize"       => atop.authorize
        }

        case asset.type
        when Stellar::AssetType.asset_type_native
          raise "native asset in allow_trust_op"
        when Stellar::AssetType.asset_type_credit_alphanum4
          hop.details["asset_type"]   = "credit_alphanum4"
          hop.details["asset_code"]   = asset.asset_code4!.strip
          hop.details["asset_issuer"] = Stellar::Convert.pk_to_address source_account
        when Stellar::AssetType.asset_type_credit_alphanum12
          hop.details["asset_type"]   = "credit_alphanum12"
          hop.details["asset_code"]   = asset.asset_code12!.strip
          hop.details["asset_issuer"] = Stellar::Convert.pk_to_address source_account
        else
          raise "Unknown asset type: #{asset.type}"
        end

      when Stellar::OperationType.account_merge
        destination  = op.body.destination!
        hop.details = {
          "account"   => Stellar::Convert.pk_to_address(source_account),
          "into"     => Stellar::Convert.pk_to_address(destination)
        }
        participant_addresses << hop.details["into"]
      when Stellar::OperationType.inflation
        #Inflation has no details, presently.
      end


      hop.save!
      hops << hop

      participant_addresses.uniq!
      # now import the participants from this operation
      participants = History::Account.where(address:participant_addresses).all

      unless participants.length == participant_addresses.length
        raise "Could not find all participants"
      end

      participants.each do |account|
        History::OperationParticipant.create!({
          history_account:   account,
          history_operation: hop,
        })
      end
    end

    hops
  end

  def import_history_effects(sctx, hops)
    heffs = []

    sctx.operations_with_results.each_with_index do |op_and_r, application_order|
      scop, scresult = *op_and_r
      hop = hops[application_order]

      heffs.concat import_history_effects_for_operation(sctx, scop, scresult, hop)
    end

    heffs
  end

  def import_history_effects_for_operation(sctx, scop, scresult, hop)
    effects = History::EffectFactory.new(hop)
    source_account = scop.source_account || sctx.source_account
    op_index = sctx.operations.index(scop)
    scopm = sctx.meta.operations![op_index]

    case hop.type_as_enum
    when Stellar::OperationType.create_account
      scop = scop.body.create_account_op!

      effects.create!("account_created", scop.destination, {
        starting_balance: as_amount(scop.starting_balance),
      })

      effects.create!("account_debited", source_account, {
        asset_type: "native",
        amount: as_amount(scop.starting_balance)
      })

      effects.create!("signer_created", scop.destination, {
        public_key: Stellar::Convert.pk_to_address(scop.destination),
        weight: DEFAULT_SIGNER_WEIGHT,
      })
    when Stellar::OperationType.payment
      scop = scop.body.payment_op!
      details = { amount: as_amount(scop.amount) }
      details.merge!  asset_details(scop.asset)
      effects.create!("account_credited", scop.destination, details)
      effects.create!("account_debited", source_account, details)
    when Stellar::OperationType.path_payment
      scop = scop.body.path_payment_op!

      dest_details = { amount: as_amount(scop.dest_amount) }
      dest_details.merge!  asset_details(scop.dest_asset)

      scresult = scresult.tr!.path_payment_result!
      source_details = { amount: as_amount(scresult.send_amount) }
      source_details.merge!  asset_details(scop.send_asset)

      effects.create!("account_credited", scop.destination, dest_details)
      effects.create!("account_debited", source_account, source_details)

      make_trades effects, source_account, scresult.success!.offers
    when Stellar::OperationType.manage_offer
      scresult = scresult.tr!.manage_offer_result!.success!
      make_trades effects, source_account, scresult.offers_claimed
    when Stellar::OperationType.create_passive_offer
      scresult = scresult.tr!.manage_offer_result!.success!
      make_trades effects, source_account, scresult.offers_claimed
    when Stellar::OperationType.set_options
      scop = scop.body.set_options_op!

      unless scop.home_domain.nil?
        effects.create!("account_home_domain_updated", source_account, {
          "home_domain" => scop.home_domain
        })
      end

      thresholds_changed = scop.low_threshold.present? ||
                           scop.med_threshold.present? ||
                           scop.high_threshold.present?


      if thresholds_changed
        details = {}
        details["low_threshold"]  = scop.low_threshold  if scop.low_threshold.present?
        details["med_threshold"]  = scop.med_threshold  if scop.med_threshold.present?
        details["high_threshold"] = scop.high_threshold if scop.high_threshold.present?
        effects.create!("account_thresholds_updated", source_account, details)
      end

      flag_changes = {}
      Stellar::AccountFlags.parse_mask(scop.set_flags || 0).each do |af|
        flag_changes [af.name] = true
      end
      Stellar::AccountFlags.parse_mask(scop.clear_flags || 0).each do |af|
        flag_changes [af.name] = false
      end

      if flag_changes.any?
        effects.create!("account_flags_updated", source_account, flag_changes)
      end

      if scop.master_weight.present?
        #TODO: BLOCKED stellar-core: differentiate signer_updated and signer_added
        #for master signer
        effect = scop.master_weight == 0 ? "signer_removed" : "signer_updated"

        effects.create!(effect, source_account, {
          public_key: Stellar::Convert.pk_to_address(source_account),
          weight: scop.master_weight,
        })
      end

      if scop.signer.present?
        effect = if scop.signer.weight == 0
                   "signer_removed"
                 else
                   #TODO: BLOCKED stellar-core: distinguish between new signers and updated signers
                   "signer_created"
                 end

        effects.create!(effect, source_account, {
          public_key: Stellar::Convert.pk_to_address(scop.signer.pub_key),
          weight: scop.signer.weight,
        })
      end

    when Stellar::OperationType.change_trust
      scop = scop.body.change_trust_op!
      effect = if scop.limit == 0
                 'trustline_removed'
               else
                 tlm = scopm.changes.first #TODO: add a less brittle method of finding the trustline entry in the meta
                 if tlm.blank?
                   'trustline_updated'
                 elsif tlm.type == Stellar::LedgerEntryChangeType.ledger_entry_created
                   'trustline_created'
                 else
                   'trustline_updated'
                 end
               end

      details = asset_details(scop.line)
      details["limit"] = as_amount(scop.limit)

      effects.create!(effect, source_account, details)
    when Stellar::OperationType.allow_trust
      scop = scop.body.allow_trust_op!
      asset = scop.asset
      effect = scop.authorize ? "trustline_authorized" : "trustline_deauthorized"
      details = {
        "trustor" => Stellar::Convert.pk_to_address(scop.trustor),
      }

      case asset.type
      when Stellar::AssetType.asset_type_native
        raise "native asset in allow_trust_op"
      when Stellar::AssetType.asset_type_credit_alphanum4
        details["asset_type"]   = "credit_alphanum4"
        details["asset_code"]   = asset.asset_code4!.strip
      when Stellar::AssetType.asset_type_credit_alphanum12
        details["asset_type"]   = "credit_alphanum12"
        details["asset_code"]   = asset.asset_code12!.strip
      else
        raise "Unknown asset type: #{asset.type}"
      end


      effects.create!(effect, source_account, details)
    when Stellar::OperationType.account_merge
      destination = scop.body.destination!
      scresult = scresult.tr!.account_merge_result!
      details = { amount: as_amount(scresult.source_account_balance!), asset_type: "native" }
      effects.create!("account_debited", source_account, details)
      effects.create!("account_credited", destination, details)
      effects.create!("account_removed", source_account, {})
    when Stellar::OperationType.inflation
      payouts = scresult.tr!.inflation_result!.payouts!

      payouts.each do |payout|
        details = { amount: as_amount(payout.amount), asset_type: "native" }
        effects.create!("account_credited", payout.destination, details)
      end
    else
      Rails.logger.info "Unknown type: #{hop.type_as_enum.name}.  skipping effects import"
    end

    effects.results
  end

  def asset_details(asset, prefix="")
    case asset.type
    when Stellar::AssetType.asset_type_native
      { "#{prefix}asset_type" => "native" }
    when Stellar::AssetType.asset_type_credit_alphanum4
      coded_asset_details(asset, prefix, "credit_alphanum4")
    when Stellar::AssetType.asset_type_credit_alphanum12
      coded_asset_details(asset, prefix, "credit_alphanum12")
    else
      raise "Unknown asset type: #{asset.type}"
    end
  end

  def coded_asset_details(asset, prefix, type)
    {
      "#{prefix}asset_type"   => type,
      "#{prefix}asset_code"   => asset.code.strip,
      "#{prefix}asset_issuer" => Stellar::Convert.pk_to_address(asset.issuer),
    }
  end

  #
  # This method ensures that we create the history_account record for the
  # master account, which is a special case because it never shows up as
  # a new account in some transaction's metadata.
  #
  def create_master_history_account!
    return if History::Account.where(id:1).any?
    History::Account.create!(address: Stellar::KeyPair.master.address, id: 1)
  end

  # given the provided account and a set of claim_offer_atoms, produce 2 trade
  # effects (one for the buyer, one for the sellar) for each claim_offer_atom
  def make_trades(effects, buyer, claim_offer_atoms)
    claim_offer_atoms.each{|coa| make_trade effects, buyer, coa}
  end

  def make_trade(effects, buyer, claimed_offer)
    seller = claimed_offer.seller_id

    buyer_details = {
      "offer_id"      => claimed_offer.offer_id,
      "seller"        => Stellar::Convert.pk_to_address(seller),
      "bought_amount" => as_amount(claimed_offer.amount_sold),
      "sold_amount"   => as_amount(claimed_offer.amount_bought),
    }
    buyer_details.merge! asset_details(claimed_offer.asset_sold, "bought_")
    buyer_details.merge! asset_details(claimed_offer.asset_bought, "sold_")

    seller_details = {
      "offer_id"      => claimed_offer.offer_id,
      "seller"        => Stellar::Convert.pk_to_address(buyer),
      "bought_amount" => as_amount(claimed_offer.amount_bought),
      "sold_amount"   => as_amount(claimed_offer.amount_sold),
    }
    seller_details.merge! asset_details(claimed_offer.asset_bought, "bought_")
    seller_details.merge! asset_details(claimed_offer.asset_sold, "sold_")

    effects.create!("trade", buyer, buyer_details)
    effects.create!("trade", seller, seller_details)
  end

  def as_amount(raw_amount)
    raw = (BigDecimal.new(raw_amount) / BigDecimal.new(Stellar::ONE)).round(7, :truncate).to_s("F")
    l, r = *raw.split(".", 2)
    r = r.ljust(7, '0')
    "#{l}.#{r}"
  end

  def price_string(price)
    raw = (BigDecimal.new(price.n) / BigDecimal.new(price.d)).round(7, :truncate).to_s("F")
    l, r = *raw.split(".", 2)
    r = r.ljust(7, '0')
    "#{l}.#{r}"
  end
end
