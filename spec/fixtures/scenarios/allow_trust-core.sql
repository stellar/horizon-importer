--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

SET search_path = public, pg_catalog;

DROP INDEX public.signersaccount;
DROP INDEX public.priceindex;
DROP INDEX public.paysissuerindex;
DROP INDEX public.ledgersbyseq;
DROP INDEX public.getsissuerindex;
DROP INDEX public.accountlines;
DROP INDEX public.accountbalances;
ALTER TABLE ONLY public.txhistory DROP CONSTRAINT txhistory_pkey;
ALTER TABLE ONLY public.txhistory DROP CONSTRAINT txhistory_ledgerseq_txindex_key;
ALTER TABLE ONLY public.trustlines DROP CONSTRAINT trustlines_pkey;
ALTER TABLE ONLY public.storestate DROP CONSTRAINT storestate_pkey;
ALTER TABLE ONLY public.signers DROP CONSTRAINT signers_pkey;
ALTER TABLE ONLY public.peers DROP CONSTRAINT peers_pkey;
ALTER TABLE ONLY public.offers DROP CONSTRAINT offers_pkey;
ALTER TABLE ONLY public.ledgerheaders DROP CONSTRAINT ledgerheaders_pkey;
ALTER TABLE ONLY public.ledgerheaders DROP CONSTRAINT ledgerheaders_ledgerseq_key;
ALTER TABLE ONLY public.accounts DROP CONSTRAINT accounts_pkey;
DROP TABLE public.txhistory;
DROP TABLE public.trustlines;
DROP TABLE public.storestate;
DROP TABLE public.signers;
DROP TABLE public.peers;
DROP TABLE public.offers;
DROP TABLE public.ledgerheaders;
DROP TABLE public.accounts;
DROP EXTENSION plpgsql;
DROP SCHEMA public;
--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA public;


--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: accounts; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE accounts (
    accountid character varying(51) NOT NULL,
    balance bigint NOT NULL,
    seqnum bigint NOT NULL,
    numsubentries integer NOT NULL,
    inflationdest character varying(51),
    homedomain character varying(32),
    thresholds text,
    flags integer NOT NULL,
    CONSTRAINT accounts_balance_check CHECK ((balance >= 0)),
    CONSTRAINT accounts_numsubentries_check CHECK ((numsubentries >= 0))
);


--
-- Name: ledgerheaders; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE ledgerheaders (
    ledgerhash character(64) NOT NULL,
    prevhash character(64) NOT NULL,
    bucketlisthash character(64) NOT NULL,
    ledgerseq integer,
    closetime bigint NOT NULL,
    data text NOT NULL,
    CONSTRAINT ledgerheaders_closetime_check CHECK ((closetime >= 0)),
    CONSTRAINT ledgerheaders_ledgerseq_check CHECK ((ledgerseq >= 0))
);


--
-- Name: offers; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE offers (
    accountid character varying(51) NOT NULL,
    offerid bigint NOT NULL,
    paysalphanumcurrency character varying(4),
    paysissuer character varying(51),
    getsalphanumcurrency character varying(4),
    getsissuer character varying(51),
    amount bigint NOT NULL,
    pricen integer NOT NULL,
    priced integer NOT NULL,
    price bigint NOT NULL,
    CONSTRAINT offers_amount_check CHECK ((amount >= 0)),
    CONSTRAINT offers_offerid_check CHECK ((offerid >= 0))
);


--
-- Name: peers; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE peers (
    ip character varying(15) NOT NULL,
    port integer DEFAULT 0 NOT NULL,
    nextattempt timestamp without time zone NOT NULL,
    numfailures integer DEFAULT 0 NOT NULL,
    rank integer DEFAULT 0 NOT NULL,
    CONSTRAINT peers_numfailures_check CHECK ((numfailures >= 0)),
    CONSTRAINT peers_port_check CHECK (((port > 0) AND (port <= 65535))),
    CONSTRAINT peers_rank_check CHECK ((rank >= 0))
);


--
-- Name: signers; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE signers (
    accountid character varying(51) NOT NULL,
    publickey character varying(51) NOT NULL,
    weight integer NOT NULL
);


--
-- Name: storestate; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE storestate (
    statename character(32) NOT NULL,
    state text
);


--
-- Name: trustlines; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE trustlines (
    accountid character varying(51) NOT NULL,
    issuer character varying(51) NOT NULL,
    alphanumcurrency character varying(4) NOT NULL,
    tlimit bigint DEFAULT 0 NOT NULL,
    balance bigint DEFAULT 0 NOT NULL,
    flags integer NOT NULL,
    CONSTRAINT trustlines_balance_check CHECK ((balance >= 0)),
    CONSTRAINT trustlines_tlimit_check CHECK ((tlimit >= 0))
);


--
-- Name: txhistory; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE txhistory (
    txid character(64) NOT NULL,
    ledgerseq integer NOT NULL,
    txindex integer NOT NULL,
    txbody text NOT NULL,
    txresult text NOT NULL,
    txmeta text NOT NULL,
    CONSTRAINT txhistory_ledgerseq_check CHECK ((ledgerseq >= 0))
);


--
-- Data for Name: accounts; Type: TABLE DATA; Schema: public; Owner: -
--

COPY accounts (accountid, balance, seqnum, numsubentries, inflationdest, homedomain, thresholds, flags) FROM stdin;
gspbxqXqEUZkiCCEFFCN9Vu4FLucdjLLdLcsV6E82Qc1T7ehsTC	99999969999999970	3	0	\N		01000000	0
gsKuurNYgtBhTSFfsCaWqNb3Ze5Je9csKTSLfjo8Ko2b1f66ayZ	9999999990	12884901889	1	\N		01000000	0
gqdUHrgHUp8uMb74HiQvYztze2ffLhVXpPwj7gEZiJRa4jhCXQ	9999999990	12884901889	1	\N		01000000	0
gsPsm67nNK8HtwMedJZFki3jAEKgg1s4nRKrHREFqTzT6ErzBiq	9999999950	12884901893	0	\N		01000000	3
\.


--
-- Data for Name: ledgerheaders; Type: TABLE DATA; Schema: public; Owner: -
--

COPY ledgerheaders (ledgerhash, prevhash, bucketlisthash, ledgerseq, closetime, data) FROM stdin;
41310a0181a3a82ff13c049369504e978734cf17da1baf02f7e4d881e8608371	0000000000000000000000000000000000000000000000000000000000000000	e71064e28d0740ac27cf07b267200ea9b8916ad1242195c015fa3012086588d3	1	0	AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA5xBk4o0HQKwnzweyZyAOqbiRatEkIZXAFfowEghliNMAAAABAAAAAAAAAAABY0V4XYoAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACgCYloA=
64d01e2065ffef7dff7b94685d189993883f56ea4d755a432920a9858c906308	41310a0181a3a82ff13c049369504e978734cf17da1baf02f7e4d881e8608371	24128cf784e4c94f58a5a72a5036a54e82b2e37c1b1b327bd8af8ab48684abf6	2	1433788280	QTEKAYGjqC/xPASTaVBOl4c0zxfaG68C9+TYgehgg3HWnizXf2VvYXCoygkt/wDezda8dXZTRIUXo6e9UAqQU+OwxEKY/BwUmvv0yJlvuSQnrkHkZJuTTKSVmRt4UrhVJBKM94TkyU9YpacqUDalToKy43wbGzJ72K+KtIaEq/YAAAACAAAAAFV133gBY0V4XYoAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACgCYloA=
ffbd643b778d784234317bc34804144f46dd4d39aea40e2d1249595e7fff5545	64d01e2065ffef7dff7b94685d189993883f56ea4d755a432920a9858c906308	59d90d92bc0c72e81d883fb80c027f37b182ac61704513789bb73916335a0409	3	1433788281	ZNAeIGX/733/e5RoXRiZk4g/VupNdVpDKSCphYyQYwhurfaT65vUxGzIk38YLQPgjXOgi+aDH9eUZ8rLLUNMH2+UXGi9FfKG00tyiRQJNT79wKDwUaevHhHOJ5ohTAeHWdkNkrwMcugdiD+4DAJ/N7GCrGFwRRN4m7c5FjNaBAkAAAADAAAAAFV133kBY0V4XYoAAAAAAAAAAAAeAAAAAAAAAAAAAAAAAAAACgCYloA=
ab189122bea098cf31a30de5a1e6d9fea96d9636f1c33a67c5bf1014ab5f5830	ffbd643b778d784234317bc34804144f46dd4d39aea40e2d1249595e7fff5545	dfc1f807794e9e054cfd97fa5367bcd2a42ffc1d831944fb4717ebd28cfa3187	4	1433788282	/71kO3eNeEI0MXvDSAQUT0bdTTmupA4tEklZXn//VUUKb7J/Gc+39/D6OCROUHxn9yt5n7fXaw69h9mzarPJ8MpeYnXFItvaqouZjHx2gNcPGAm4zhpik5//cvnqVcnf38H4B3lOngVM/Zf6U2e80qQv/B2DGUT7Rxfr0oz6MYcAAAAEAAAAAFV133oBY0V4XYoAAAAAAAAAAAAyAAAAAAAAAAAAAAAAAAAACgCYloA=
b2bad82e32635439f9cf2e5918a6bc2cae2143a62a898b1f3575615d845210ef	ab189122bea098cf31a30de5a1e6d9fea96d9636f1c33a67c5bf1014ab5f5830	80f3b27cc42c7a7bac425aac36c450f19d44e19b8919513b6d781de3af19dbec	5	1433788283	qxiRIr6gmM8xow3loebZ/qltljbxwzpnxb8QFKtfWDDY+WpiPRx8BLMLKhge3KjH4/Ez63u36WKuZljFLzklLg18IQzF9Pld2P+exAmYqx8tInih2PIQ8XARAWD/BWNEgPOyfMQsenusQlqsNsRQ8Z1E4ZuJGVE7bXgd468Z2+wAAAAFAAAAAFV133sBY0V4XYoAAAAAAAAAAABGAAAAAAAAAAAAAAAAAAAACgCYloA=
f0a20a4bfbfe6b8355e06deb197bf445c87dcc33a3ea3a19f08040ead662add9	b2bad82e32635439f9cf2e5918a6bc2cae2143a62a898b1f3575615d845210ef	e082df2f5d88675c331f75c92bb2c1e2d15d98cc1a4e55b291105c8b84595182	6	1433788284	srrYLjJjVDn5zy5ZGKa8LK4hQ6YqiYsfNXVhXYRSEO8VDoSLhoOLyz+vWe4l0lutt90I5CtE3cCaAQ0Y3930I+YtusbjRRZj+cibBQtZpqlSUlxDT7DR3Pvhb1Lfseu+4ILfL12IZ1wzH3XJK7LB4tFdmMwaTlWykRBci4RZUYIAAAAGAAAAAFV133wBY0V4XYoAAAAAAAAAAABaAAAAAAAAAAAAAAAAAAAACgCYloA=
635248e4586eb3ffe5d1fc23b516d125eef7b3c986d7ea3b11630aa0352338f7	f0a20a4bfbfe6b8355e06deb197bf445c87dcc33a3ea3a19f08040ead662add9	a992763405c7130775b35d17dc88a50593d9a617a1be1b8212382d7a5637934d	7	1433788285	8KIKS/v+a4NV4G3rGXv0Rch9zDOj6joZ8IBA6tZirdl5ZUbELpQsBBx+zB4H+ivvR9lXrsTCtquTpOp5FfCJWxcwczNYgFUn8N0lFL1EtlOs//fh5/vri29R9YXXDhDJqZJ2NAXHEwd1s10X3IilBZPZphehvhuCEjgtelY3k00AAAAHAAAAAFV1330BY0V4XYoAAAAAAAAAAABkAAAAAAAAAAAAAAAAAAAACgCYloA=
\.


--
-- Data for Name: offers; Type: TABLE DATA; Schema: public; Owner: -
--

COPY offers (accountid, offerid, paysalphanumcurrency, paysissuer, getsalphanumcurrency, getsissuer, amount, pricen, priced, price) FROM stdin;
\.


--
-- Data for Name: peers; Type: TABLE DATA; Schema: public; Owner: -
--

COPY peers (ip, port, nextattempt, numfailures, rank) FROM stdin;
\.


--
-- Data for Name: signers; Type: TABLE DATA; Schema: public; Owner: -
--

COPY signers (accountid, publickey, weight) FROM stdin;
\.


--
-- Data for Name: storestate; Type: TABLE DATA; Schema: public; Owner: -
--

COPY storestate (statename, state) FROM stdin;
databaseinitialized             	true
forcescponnextlaunch            	false
lastclosedledger                	635248e4586eb3ffe5d1fc23b516d125eef7b3c986d7ea3b11630aa0352338f7
historyarchivestate             	{\n    "version": 0,\n    "currentLedger": 7,\n    "currentBuckets": [\n        {\n            "curr": "b5fdf268388f33cc1921d89ae083b2c1edad4d7f7a84aa4e2acc06be8ea6d35e",\n            "next": {\n                "state": 0\n            },\n            "snap": "2f276c3db20ff9370164e026ee00f3a20da2884e94b74b1430658bd0912836ee"\n        },\n        {\n            "curr": "e46a62f2f2cb46a177fa4ef4ca9c6c956795c0b82a993710fa2611f42107d84f",\n            "next": {\n                "state": 1,\n                "output": "2f276c3db20ff9370164e026ee00f3a20da2884e94b74b1430658bd0912836ee"\n            },\n            "snap": "0000000000000000000000000000000000000000000000000000000000000000"\n        },\n        {\n            "curr": "0000000000000000000000000000000000000000000000000000000000000000",\n            "next": {\n                "state": 0\n            },\n            "snap": "0000000000000000000000000000000000000000000000000000000000000000"\n        },\n        {\n            "curr": "0000000000000000000000000000000000000000000000000000000000000000",\n            "next": {\n                "state": 0\n            },\n            "snap": "0000000000000000000000000000000000000000000000000000000000000000"\n        },\n        {\n            "curr": "0000000000000000000000000000000000000000000000000000000000000000",\n            "next": {\n                "state": 0\n            },\n            "snap": "0000000000000000000000000000000000000000000000000000000000000000"\n        },\n        {\n            "curr": "0000000000000000000000000000000000000000000000000000000000000000",\n            "next": {\n                "state": 0\n            },\n            "snap": "0000000000000000000000000000000000000000000000000000000000000000"\n        },\n        {\n            "curr": "0000000000000000000000000000000000000000000000000000000000000000",\n            "next": {\n                "state": 0\n            },\n            "snap": "0000000000000000000000000000000000000000000000000000000000000000"\n        },\n        {\n            "curr": "0000000000000000000000000000000000000000000000000000000000000000",\n            "next": {\n                "state": 0\n            },\n            "snap": "0000000000000000000000000000000000000000000000000000000000000000"\n        },\n        {\n            "curr": "0000000000000000000000000000000000000000000000000000000000000000",\n            "next": {\n                "state": 0\n            },\n            "snap": "0000000000000000000000000000000000000000000000000000000000000000"\n        },\n        {\n            "curr": "0000000000000000000000000000000000000000000000000000000000000000",\n            "next": {\n                "state": 0\n            },\n            "snap": "0000000000000000000000000000000000000000000000000000000000000000"\n        },\n        {\n            "curr": "0000000000000000000000000000000000000000000000000000000000000000",\n            "next": {\n                "state": 0\n            },\n            "snap": "0000000000000000000000000000000000000000000000000000000000000000"\n        }\n    ]\n}
\.


--
-- Data for Name: trustlines; Type: TABLE DATA; Schema: public; Owner: -
--

COPY trustlines (accountid, issuer, alphanumcurrency, tlimit, balance, flags) FROM stdin;
gsKuurNYgtBhTSFfsCaWqNb3Ze5Je9csKTSLfjo8Ko2b1f66ayZ	gsPsm67nNK8HtwMedJZFki3jAEKgg1s4nRKrHREFqTzT6ErzBiq	USD	9223372036854775807	0	1
gqdUHrgHUp8uMb74HiQvYztze2ffLhVXpPwj7gEZiJRa4jhCXQ	gsPsm67nNK8HtwMedJZFki3jAEKgg1s4nRKrHREFqTzT6ErzBiq	USD	4000	0	0
\.


--
-- Data for Name: txhistory; Type: TABLE DATA; Schema: public; Owner: -
--

COPY txhistory (txid, ledgerseq, txindex, txbody, txresult, txmeta) FROM stdin;
e2b3ecd737eb4c241e7abe15a6d079dbe1de708263f59d1882c05eb7d0e89c08	3	1	iZsoQO1WNsVt3F8Usjl1958bojiNJpTkxW7N3clg5e8AAAAKAAAAAAAAAAEAAAAAAAAAAAAAAAEAAAAAAAAAALW4F0ehO6Ay9C0PsGEgvc1711U98Yj4mLkm9Q75kC3vAAAAAlQL5AAAAAABiZsoQHDoAd/mr0zgQ1i9SghJpb+MSD4VgZObbZmdJT2eusSp5fG0KzRd1nr+da5tBzVpotbKp2nbzkdvrnG87OuT+wg=	4rPs1zfrTCQeer4VptB52+HecIJj9Z0YgsBet9DonAgAAAAAAAAACgAAAAAAAAABAAAAAAAAAAAAAAAA	AAAAAgAAAAAAAAAAtbgXR6E7oDL0LQ+wYSC9zXvXVT3xiPiYuSb1DvmQLe8AAAACVAvkAAAAAAMAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAQAAAACJmyhA7VY2xW3cXxSyOXX3nxuiOI0mlOTFbs3dyWDl7wFjRXYJfhv2AAAAAAAAAAEAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAA=
9692abb6739c52f1b76a2bc1ecc515763e8c481f8c46ac0bb13386305040af99	3	2	iZsoQO1WNsVt3F8Usjl1958bojiNJpTkxW7N3clg5e8AAAAKAAAAAAAAAAIAAAAAAAAAAAAAAAEAAAAAAAAAAK6jei3jmoI8TGlD/egc37PXtHKKzWV8wViZBaCu5L5MAAAAAlQL5AAAAAABiZsoQKT+Ezzq7qTSGD6MIs2AWZhwMabtkbGOnaYmEhRyhIIVxiP1/kti5dxEcqKEPRlLhh4ztkmYlYW/Grv5u6FW0Qs=	lpKrtnOcUvG3aivB7MUVdj6MSB+MRqwLsTOGMFBAr5kAAAAAAAAACgAAAAAAAAABAAAAAAAAAAAAAAAA	AAAAAgAAAAAAAAAArqN6LeOagjxMaUP96Bzfs9e0corNZXzBWJkFoK7kvkwAAAACVAvkAAAAAAMAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAQAAAACJmyhA7VY2xW3cXxSyOXX3nxuiOI0mlOTFbs3dyWDl7wFjRXO1cjfsAAAAAAAAAAIAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAA=
7aa3ca5873e4f8bd88715475d8be02fe3d31c82becad84fe1b41541fd442ec21	3	3	iZsoQO1WNsVt3F8Usjl1958bojiNJpTkxW7N3clg5e8AAAAKAAAAAAAAAAMAAAAAAAAAAAAAAAEAAAAAAAAAAG5oJtVdnYOVdZqtXpTHBtbcY0mCmfcBIKEgWnlvFIhaAAAAAlQL5AAAAAABiZsoQPiR3EJQazqwgAQwJPttGbdDJf3MDXCEOV8IUw7bB3ogXaWa7aXkJtXbJk/LVMIBdCrh/Pz4aO3/z4VxCKvZ3QI=	eqPKWHPk+L2IcVR12L4C/j0xyCvsrYT+G0FUH9RC7CEAAAAAAAAACgAAAAAAAAABAAAAAAAAAAAAAAAA	AAAAAgAAAAAAAAAAbmgm1V2dg5V1mq1elMcG1txjSYKZ9wEgoSBaeW8UiFoAAAACVAvkAAAAAAMAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAQAAAACJmyhA7VY2xW3cXxSyOXX3nxuiOI0mlOTFbs3dyWDl7wFjRXFhZlPiAAAAAAAAAAMAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAA=
84285aaf873ec717ad6de8e010ed5d51c9864e7d16613a6fa41232a2e230ff02	4	1	tbgXR6E7oDL0LQ+wYSC9zXvXVT3xiPiYuSb1DvmQLe8AAAAKAAAAAwAAAAEAAAAAAAAAAAAAAAEAAAAAAAAABAAAAAAAAAABAAAAAAAAAAEAAAABAAAAAAAAAAAAAAAAAAAAAbW4F0dEY9nwJz2gavwKT1ltnDv9rwYefcgqR2JpNbycaA3eYBDhR4e9XH+IgYqQDCoV+K3osjmK+Pcjext55ZBAkUcB	hChar4c+xxetbejgEO1dUcmGTn0WYTpvpBIyouIw/wIAAAAAAAAACgAAAAAAAAABAAAAAAAAAAQAAAAA	AAAAAQAAAAEAAAAAtbgXR6E7oDL0LQ+wYSC9zXvXVT3xiPiYuSb1DvmQLe8AAAACVAvj9gAAAAMAAAABAAAAAAAAAAAAAAABAQAAAAAAAAAAAAAA
3436d145c1609a134c21cda2f148a36087898382af42913dde59f19dc3881de3	4	2	tbgXR6E7oDL0LQ+wYSC9zXvXVT3xiPiYuSb1DvmQLe8AAAAKAAAAAwAAAAIAAAAAAAAAAAAAAAEAAAAAAAAABAAAAAAAAAABAAAAAAAAAAEAAAACAAAAAAAAAAAAAAAAAAAAAbW4F0c2FXHWWYTZoxa4svKNnAEZeTSL4Z6Rx979MDonlm3o6ctzwj6wIrmT6AYiMXHRNurVhdmuchl9mo4jq5xKssoL	NDbRRcFgmhNMIc2i8UijYIeJg4KvQpE93lnxncOIHeMAAAAAAAAACgAAAAAAAAABAAAAAAAAAAQAAAAA	AAAAAQAAAAEAAAAAtbgXR6E7oDL0LQ+wYSC9zXvXVT3xiPiYuSb1DvmQLe8AAAACVAvj7AAAAAMAAAACAAAAAAAAAAAAAAADAQAAAAAAAAAAAAAA
87a445ed06c79066dbb7bc3590271091008a859f1a89ac16df336f8a3695922f	5	1	rqN6LeOagjxMaUP96Bzfs9e0corNZXzBWJkFoK7kvkwAAAAKAAAAAwAAAAEAAAAAAAAAAAAAAAEAAAAAAAAABQAAAAFVU0QAtbgXR6E7oDL0LQ+wYSC9zXvXVT3xiPiYuSb1DvmQLe9//////////wAAAAGuo3ot9c0nvpho6+8IB5dVUv/rCwPzGDS6vf6F3mcg6/SqpSgmK8LKOxx1I5mJuemKaHxWiOiRvsCJi4eqhIlRtozrCw==	h6RF7QbHkGbbt7w1kCcQkQCKhZ8aiawW3zNvijaVki8AAAAAAAAACgAAAAAAAAABAAAAAAAAAAUAAAAA	AAAAAgAAAAAAAAABrqN6LeOagjxMaUP96Bzfs9e0corNZXzBWJkFoK7kvkwAAAABVVNEALW4F0ehO6Ay9C0PsGEgvc1711U98Yj4mLkm9Q75kC3vAAAAAAAAAAB//////////wAAAAAAAAABAAAAAK6jei3jmoI8TGlD/egc37PXtHKKzWV8wViZBaCu5L5MAAAAAlQL4/YAAAADAAAAAQAAAAEAAAAAAAAAAAEAAAAAAAAAAAAAAA==
7e42be6fd5fde3538b6b44533d0a18ec52e507007c674b9ff58811823abf2839	5	2	bmgm1V2dg5V1mq1elMcG1txjSYKZ9wEgoSBaeW8UiFoAAAAKAAAAAwAAAAEAAAAAAAAAAAAAAAEAAAAAAAAABQAAAAFVU0QAtbgXR6E7oDL0LQ+wYSC9zXvXVT3xiPiYuSb1DvmQLe8AAAAAAAAPoAAAAAFuaCbVXb7uy95otBvj3IRzwF4PgyBLmlzTPDjyhZPdXkB00QvJzNkCl+Xqn+XuXc871pjfm3kYi/FAzIy1A0548kpABw==	fkK+b9X941OLa0RTPQoY7FLlBwB8Z0uf9YgRgjq/KDkAAAAAAAAACgAAAAAAAAABAAAAAAAAAAUAAAAA	AAAAAgAAAAAAAAABbmgm1V2dg5V1mq1elMcG1txjSYKZ9wEgoSBaeW8UiFoAAAABVVNEALW4F0ehO6Ay9C0PsGEgvc1711U98Yj4mLkm9Q75kC3vAAAAAAAAAAAAAAAAAAAPoAAAAAAAAAABAAAAAG5oJtVdnYOVdZqtXpTHBtbcY0mCmfcBIKEgWnlvFIhaAAAAAlQL4/YAAAADAAAAAQAAAAEAAAAAAAAAAAEAAAAAAAAAAAAAAA==
2b35d76754d9bd783616a0cd41a1c29894e9a111153e198680c35db25faebf18	6	1	tbgXR6E7oDL0LQ+wYSC9zXvXVT3xiPiYuSb1DvmQLe8AAAAKAAAAAwAAAAMAAAAAAAAAAAAAAAEAAAAAAAAABq6jei3jmoI8TGlD/egc37PXtHKKzWV8wViZBaCu5L5MAAAAAVVTRAAAAAABAAAAAbW4F0c/ymEZlr4bOW0JG/bRBop1bcHiFUxZu/KELRj4H/uu+EY0SNZ0oiso8cQxrcZxIu0E8RVL7337sM073cRaM8MD	KzXXZ1TZvXg2FqDNQaHCmJTpoREVPhmGgMNdsl+uvxgAAAAAAAAACgAAAAAAAAABAAAAAAAAAAYAAAAA	AAAAAgAAAAEAAAAAtbgXR6E7oDL0LQ+wYSC9zXvXVT3xiPiYuSb1DvmQLe8AAAACVAvj4gAAAAMAAAADAAAAAAAAAAAAAAADAQAAAAAAAAAAAAAAAAAAAQAAAAGuo3ot45qCPExpQ/3oHN+z17Ryis1lfMFYmQWgruS+TAAAAAFVU0QAtbgXR6E7oDL0LQ+wYSC9zXvXVT3xiPiYuSb1DvmQLe8AAAAAAAAAAH//////////AAAAAQ==
a5a79bb163f56e708436ce6081b3c7ce7bc2f508e161affb8ab01648a81c0e59	6	2	tbgXR6E7oDL0LQ+wYSC9zXvXVT3xiPiYuSb1DvmQLe8AAAAKAAAAAwAAAAQAAAAAAAAAAAAAAAEAAAAAAAAABm5oJtVdnYOVdZqtXpTHBtbcY0mCmfcBIKEgWnlvFIhaAAAAAVVTRAAAAAABAAAAAbW4F0eCyyOqba7NRWBz6YkJnB6bdTZy4lGk/K4v4HvhwBL5lA3Lp9nV9/f8hZC2a9xjwe1KcUotj5qcYNyHZZrbO1sK	paebsWP1bnCENs5ggbPHznvC9QjhYa/7irAWSKgcDlkAAAAAAAAACgAAAAAAAAABAAAAAAAAAAYAAAAA	AAAAAgAAAAEAAAAAtbgXR6E7oDL0LQ+wYSC9zXvXVT3xiPiYuSb1DvmQLe8AAAACVAvj2AAAAAMAAAAEAAAAAAAAAAAAAAADAQAAAAAAAAAAAAAAAAAAAQAAAAFuaCbVXZ2DlXWarV6UxwbW3GNJgpn3ASChIFp5bxSIWgAAAAFVU0QAtbgXR6E7oDL0LQ+wYSC9zXvXVT3xiPiYuSb1DvmQLe8AAAAAAAAAAAAAAAAAAA+gAAAAAQ==
cc7ed676047cd2860c4538bd306dfbe23e744d0c070a8397eb1d678de9c95f3a	7	1	tbgXR6E7oDL0LQ+wYSC9zXvXVT3xiPiYuSb1DvmQLe8AAAAKAAAAAwAAAAUAAAAAAAAAAAAAAAEAAAAAAAAABm5oJtVdnYOVdZqtXpTHBtbcY0mCmfcBIKEgWnlvFIhaAAAAAVVTRAAAAAAAAAAAAbW4F0c6P8rASp4FCBODje3Kcw9D00wUZUgvY2PxggnZux5fXugsKy9+w7+BeiIFE5oHZYVS0i5ANFWo92DuX4BSTb4H	zH7WdgR80oYMRTi9MG374j50TQwHCoOX6x1njenJXzoAAAAAAAAACgAAAAAAAAABAAAAAAAAAAYAAAAA	AAAAAgAAAAEAAAAAtbgXR6E7oDL0LQ+wYSC9zXvXVT3xiPiYuSb1DvmQLe8AAAACVAvjzgAAAAMAAAAFAAAAAAAAAAAAAAADAQAAAAAAAAAAAAAAAAAAAQAAAAFuaCbVXZ2DlXWarV6UxwbW3GNJgpn3ASChIFp5bxSIWgAAAAFVU0QAtbgXR6E7oDL0LQ+wYSC9zXvXVT3xiPiYuSb1DvmQLe8AAAAAAAAAAAAAAAAAAA+gAAAAAA==
\.


--
-- Name: accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (accountid);


--
-- Name: ledgerheaders_ledgerseq_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ledgerheaders
    ADD CONSTRAINT ledgerheaders_ledgerseq_key UNIQUE (ledgerseq);


--
-- Name: ledgerheaders_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ledgerheaders
    ADD CONSTRAINT ledgerheaders_pkey PRIMARY KEY (ledgerhash);


--
-- Name: offers_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY offers
    ADD CONSTRAINT offers_pkey PRIMARY KEY (offerid);


--
-- Name: peers_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY peers
    ADD CONSTRAINT peers_pkey PRIMARY KEY (ip, port);


--
-- Name: signers_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY signers
    ADD CONSTRAINT signers_pkey PRIMARY KEY (accountid, publickey);


--
-- Name: storestate_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY storestate
    ADD CONSTRAINT storestate_pkey PRIMARY KEY (statename);


--
-- Name: trustlines_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY trustlines
    ADD CONSTRAINT trustlines_pkey PRIMARY KEY (accountid, issuer, alphanumcurrency);


--
-- Name: txhistory_ledgerseq_txindex_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY txhistory
    ADD CONSTRAINT txhistory_ledgerseq_txindex_key UNIQUE (ledgerseq, txindex);


--
-- Name: txhistory_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY txhistory
    ADD CONSTRAINT txhistory_pkey PRIMARY KEY (txid, ledgerseq);


--
-- Name: accountbalances; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX accountbalances ON accounts USING btree (balance);


--
-- Name: accountlines; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX accountlines ON trustlines USING btree (accountid);


--
-- Name: getsissuerindex; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX getsissuerindex ON offers USING btree (getsissuer);


--
-- Name: ledgersbyseq; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX ledgersbyseq ON ledgerheaders USING btree (ledgerseq);


--
-- Name: paysissuerindex; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX paysissuerindex ON offers USING btree (paysissuer);


--
-- Name: priceindex; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX priceindex ON offers USING btree (price);


--
-- Name: signersaccount; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX signersaccount ON signers USING btree (accountid);


--
-- Name: public; Type: ACL; Schema: -; Owner: -
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM nullstyle;
GRANT ALL ON SCHEMA public TO nullstyle;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

