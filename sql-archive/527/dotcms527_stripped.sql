--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.17
-- Dumped by pg_dump version 9.6.17

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: bigIntBoolResult(boolean, bigint); Type: FUNCTION; Schema: public; Owner: dotcms_dev
--

CREATE FUNCTION public."bigIntBoolResult"("boolParam" boolean, "intParam" bigint) RETURNS boolean
    LANGUAGE sql
    AS $_$select case
		WHEN $1 AND $2 != 0 then true
		WHEN $1 != true AND $2 = 0 then true
		ELSE false
	END$_$;


ALTER FUNCTION public."bigIntBoolResult"("boolParam" boolean, "intParam" bigint) OWNER TO dotcms_dev;

--
-- Name: boolBigIntResult(bigint, boolean); Type: FUNCTION; Schema: public; Owner: dotcms_dev
--

CREATE FUNCTION public."boolBigIntResult"("intParam" bigint, "boolParam" boolean) RETURNS boolean
    LANGUAGE sql
    AS $_$select case
		WHEN $2 AND $1 != 0 then true
		WHEN $2 != true AND $1 = 0 then true
		ELSE false
	END$_$;


ALTER FUNCTION public."boolBigIntResult"("intParam" bigint, "boolParam" boolean) OWNER TO dotcms_dev;

--
-- Name: boolIntResult(integer, boolean); Type: FUNCTION; Schema: public; Owner: dotcms_dev
--

CREATE FUNCTION public."boolIntResult"("intParam" integer, "boolParam" boolean) RETURNS boolean
    LANGUAGE sql
    AS $_$select case
		WHEN $2 AND $1 != 0 then true
		WHEN $2 != true AND $1 = 0 then true
		ELSE false
	END$_$;


ALTER FUNCTION public."boolIntResult"("intParam" integer, "boolParam" boolean) OWNER TO dotcms_dev;

--
-- Name: check_child_assets(); Type: FUNCTION; Schema: public; Owner: dotcms_dev
--

CREATE FUNCTION public.check_child_assets() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
   pathCount integer;
BEGIN
   IF (tg_op = 'DELETE') THEN
      IF(OLD.asset_type ='folder') THEN
	   select count(*) into pathCount from identifier where parent_path = OLD.parent_path||OLD.asset_name||'/'  and host_inode = OLD.host_inode;
	END IF;
	IF(OLD.asset_type ='contentlet') THEN
	   select count(*) into pathCount from identifier where host_inode = OLD.id;
	END IF;
	IF (pathCount > 0 )THEN
	  RAISE EXCEPTION 'Cannot delete as this path has children';
	  RETURN NULL;
	ELSE
	  RETURN OLD;
	END IF;
   END IF;
   RETURN NULL;
END
$$;


ALTER FUNCTION public.check_child_assets() OWNER TO dotcms_dev;

--
-- Name: container_versions_check(); Type: FUNCTION; Schema: public; Owner: dotcms_dev
--

CREATE FUNCTION public.container_versions_check() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  DECLARE
	versionsCount integer;
  BEGIN
  IF (tg_op = 'DELETE') THEN
    select count(*) into versionsCount from dot_containers where identifier = OLD.identifier;
    IF (versionsCount = 0)THEN
	DELETE from identifier where id = OLD.identifier;
    ELSE
	RETURN OLD;
    END IF;
  END IF;
RETURN NULL;
END
$$;


ALTER FUNCTION public.container_versions_check() OWNER TO dotcms_dev;

--
-- Name: content_versions_check(); Type: FUNCTION; Schema: public; Owner: dotcms_dev
--

CREATE FUNCTION public.content_versions_check() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
   DECLARE
       versionsCount integer;
   BEGIN
       IF (tg_op = 'DELETE') THEN
         select count(*) into versionsCount from contentlet where identifier = OLD.identifier;
         IF (versionsCount = 0)THEN
		DELETE from identifier where id = OLD.identifier;
	   ELSE
	      RETURN OLD;
	   END IF;
	END IF;
   RETURN NULL;
   END
  $$;


ALTER FUNCTION public.content_versions_check() OWNER TO dotcms_dev;

--
-- Name: dotfolderpath(text, text); Type: FUNCTION; Schema: public; Owner: dotcms_dev
--

CREATE FUNCTION public.dotfolderpath(parent_path text, asset_name text) RETURNS text
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF(parent_path='/System folder') THEN
    RETURN '/';
  ELSE
    RETURN parent_path || asset_name || '/';
  END IF;
END;$$;


ALTER FUNCTION public.dotfolderpath(parent_path text, asset_name text) OWNER TO dotcms_dev;

--
-- Name: folder_identifier_check(); Type: FUNCTION; Schema: public; Owner: dotcms_dev
--

CREATE FUNCTION public.folder_identifier_check() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
   versionsCount integer;
BEGIN
   IF (tg_op = 'DELETE') THEN
      select count(*) into versionsCount from folder where identifier = OLD.identifier;
	IF (versionsCount = 0)THEN
	  DELETE from identifier where id = OLD.identifier;
	ELSE
	  RETURN OLD;
	END IF;
   END IF;
   RETURN NULL;
END
$$;


ALTER FUNCTION public.folder_identifier_check() OWNER TO dotcms_dev;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: identifier; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.identifier (
    id character varying(36) NOT NULL,
    parent_path character varying(255),
    asset_name character varying(255),
    host_inode character varying(36),
    asset_type character varying(64),
    syspublish_date timestamp without time zone,
    sysexpire_date timestamp without time zone
);


ALTER TABLE public.identifier OWNER TO dotcms_dev;

--
-- Name: full_path_lc(public.identifier); Type: FUNCTION; Schema: public; Owner: dotcms_dev
--

CREATE FUNCTION public.full_path_lc(public.identifier) RETURNS text
    LANGUAGE sql
    AS $_$ SELECT CASE WHEN $1.parent_path = '/System folder' then '/' else LOWER($1.parent_path || $1.asset_name) end; $_$;


ALTER FUNCTION public.full_path_lc(public.identifier) OWNER TO dotcms_dev;

--
-- Name: identifier_host_inode_check(); Type: FUNCTION; Schema: public; Owner: dotcms_dev
--

CREATE FUNCTION public.identifier_host_inode_check() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
	inodeType varchar(100);
BEGIN
  IF (tg_op = 'INSERT' OR tg_op = 'UPDATE') AND substr(NEW.asset_type, 0, 8) <> 'content' AND
		(NEW.host_inode IS NULL OR NEW.host_inode = '') THEN
		RAISE EXCEPTION 'Cannot insert/update a null or empty host inode for this kind of identifier';
		RETURN NULL;
  ELSE
		RETURN NEW;
  END IF;

  RETURN NULL;
END
$$;


ALTER FUNCTION public.identifier_host_inode_check() OWNER TO dotcms_dev;

--
-- Name: identifier_parent_path_check(); Type: FUNCTION; Schema: public; Owner: dotcms_dev
--

CREATE FUNCTION public.identifier_parent_path_check() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
 DECLARE
    folderId varchar(100);
  BEGIN
     IF (tg_op = 'INSERT' OR tg_op = 'UPDATE') THEN
      IF(NEW.parent_path='/') OR (NEW.parent_path='/System folder') THEN
        RETURN NEW;
     ELSE
      select id into folderId from identifier where asset_type='folder' and host_inode = NEW.host_inode and parent_path||asset_name||'/' = NEW.parent_path and id <> NEW.id;
      IF FOUND THEN
        RETURN NEW;
      ELSE
        RAISE EXCEPTION 'Cannot insert/update for this path does not exist for the given host';
        RETURN NULL;
      END IF;
     END IF;
    END IF;
RETURN NULL;
END
  $$;


ALTER FUNCTION public.identifier_parent_path_check() OWNER TO dotcms_dev;

--
-- Name: intBoolResult(boolean, integer); Type: FUNCTION; Schema: public; Owner: dotcms_dev
--

CREATE FUNCTION public."intBoolResult"("boolParam" boolean, "intParam" integer) RETURNS boolean
    LANGUAGE sql
    AS $_$select case
		WHEN $1 AND $2 != 0 then true
		WHEN $1 != true AND $2 = 0 then true
		ELSE false
	END$_$;


ALTER FUNCTION public."intBoolResult"("boolParam" boolean, "intParam" integer) OWNER TO dotcms_dev;

--
-- Name: link_versions_check(); Type: FUNCTION; Schema: public; Owner: dotcms_dev
--

CREATE FUNCTION public.link_versions_check() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  DECLARE
	versionsCount integer;
  BEGIN
  IF (tg_op = 'DELETE') THEN
    select count(*) into versionsCount from links where identifier = OLD.identifier;
    IF (versionsCount = 0)THEN
	DELETE from identifier where id = OLD.identifier;
    ELSE
	RETURN OLD;
    END IF;
  END IF;
RETURN NULL;
END
$$;


ALTER FUNCTION public.link_versions_check() OWNER TO dotcms_dev;

--
-- Name: dist_reindex_journal; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.dist_reindex_journal (
    id bigint NOT NULL,
    inode_to_index character varying(100) NOT NULL,
    ident_to_index character varying(100) NOT NULL,
    serverid character varying(64),
    priority integer NOT NULL,
    time_entered timestamp without time zone DEFAULT ('now'::text)::date NOT NULL,
    index_val character varying(325),
    dist_action integer DEFAULT 1 NOT NULL
);


ALTER TABLE public.dist_reindex_journal OWNER TO dotcms_dev;

--
-- Name: load_records_to_index(character varying, integer, integer); Type: FUNCTION; Schema: public; Owner: dotcms_dev
--

CREATE FUNCTION public.load_records_to_index(server_id character varying, records_to_fetch integer, priority_level integer) RETURNS SETOF public.dist_reindex_journal
    LANGUAGE plpgsql
    AS $$
DECLARE
   dj dist_reindex_journal;
BEGIN

    FOR dj IN SELECT * FROM dist_reindex_journal
       WHERE serverid IS NULL
       AND priority <= priority_level
       ORDER BY priority ASC
       LIMIT records_to_fetch
       FOR UPDATE
    LOOP
        UPDATE dist_reindex_journal SET serverid=server_id WHERE id=dj.id;
        RETURN NEXT dj;
    END LOOP;

END$$;


ALTER FUNCTION public.load_records_to_index(server_id character varying, records_to_fetch integer, priority_level integer) OWNER TO dotcms_dev;

--
-- Name: rename_folder_and_assets(); Type: FUNCTION; Schema: public; Owner: dotcms_dev
--

CREATE FUNCTION public.rename_folder_and_assets() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
   old_parent_path varchar(255);
   old_path varchar(255);
   new_path varchar(255);
   old_name varchar(255);
   hostInode varchar(100);
BEGIN
   IF (tg_op = 'UPDATE' AND NEW.name<>OLD.name) THEN
      select asset_name,parent_path,host_inode INTO old_name,old_parent_path,hostInode from identifier where id = NEW.identifier;
      old_path := old_parent_path || old_name || '/';
      new_path := old_parent_path || NEW.name || '/';
      UPDATE identifier SET asset_name = NEW.name where id = NEW.identifier;
      PERFORM renameFolderChildren(old_path,new_path,hostInode);
      RETURN NEW;
   END IF;
RETURN NULL;
END
$$;


ALTER FUNCTION public.rename_folder_and_assets() OWNER TO dotcms_dev;

--
-- Name: renamefolderchildren(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: dotcms_dev
--

CREATE FUNCTION public.renamefolderchildren(old_path character varying, new_path character varying, hostinode character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
   fi identifier;
   new_folder_path varchar(255);
   old_folder_path varchar(255);
BEGIN
    UPDATE identifier SET  parent_path  = new_path where parent_path = old_path and host_inode = hostInode;
    FOR fi IN select * from identifier where asset_type='folder' and parent_path = new_path and host_inode = hostInode LOOP
	 new_folder_path := new_path ||fi.asset_name||'/';
	 old_folder_path := old_path ||fi.asset_name||'/';
	 PERFORM renameFolderChildren(old_folder_path,new_folder_path,hostInode);
    END LOOP;
END
$$;


ALTER FUNCTION public.renamefolderchildren(old_path character varying, new_path character varying, hostinode character varying) OWNER TO dotcms_dev;

--
-- Name: structure_host_folder_check(); Type: FUNCTION; Schema: public; Owner: dotcms_dev
--

CREATE FUNCTION public.structure_host_folder_check() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    folderInode varchar(100);
    hostInode varchar(100);
BEGIN
    IF ((tg_op = 'INSERT' OR tg_op = 'UPDATE') AND (NEW.host IS NOT NULL AND NEW.host <> '' AND NEW.host <> 'SYSTEM_HOST'
          AND NEW.folder IS NOT NULL AND NEW.folder <> 'SYSTEM_FOLDER' AND NEW.folder <> '')) THEN
          select host_inode,folder.inode INTO hostInode,folderInode from folder,identifier where folder.identifier = identifier.id and folder.inode=NEW.folder;
	  IF (FOUND AND NEW.host = hostInode) THEN
		 RETURN NEW;
	  ELSE
		 RAISE EXCEPTION 'Cannot assign host/folder to structure, folder does not belong to given host';
		 RETURN NULL;
	  END IF;
    ELSE
        IF((tg_op = 'INSERT' OR tg_op = 'UPDATE') AND (NEW.host IS NULL OR NEW.host = '' OR NEW.host= 'SYSTEM_HOST'
           OR NEW.folder IS NULL OR NEW.folder = '' OR NEW.folder = 'SYSTEM_FOLDER')) THEN
          IF(NEW.host = 'SYSTEM_HOST' OR NEW.host IS NULL OR NEW.host = '') THEN
             NEW.host = 'SYSTEM_HOST';
             NEW.folder = 'SYSTEM_FOLDER';
          END IF;
          IF(NEW.folder = 'SYSTEM_FOLDER' OR NEW.folder IS NULL OR NEW.folder = '') THEN
             NEW.folder = 'SYSTEM_FOLDER';
          END IF;
        RETURN NEW;
        END IF;
    END IF;
  RETURN NULL;
END
$$;


ALTER FUNCTION public.structure_host_folder_check() OWNER TO dotcms_dev;

--
-- Name: template_versions_check(); Type: FUNCTION; Schema: public; Owner: dotcms_dev
--

CREATE FUNCTION public.template_versions_check() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  DECLARE
	versionsCount integer;
  BEGIN
  IF (tg_op = 'DELETE') THEN
    select count(*) into versionsCount from template where identifier = OLD.identifier;
    IF (versionsCount = 0)THEN
	DELETE from identifier where id = OLD.identifier;
    ELSE
	RETURN OLD;
    END IF;
  END IF;
RETURN NULL;
END
$$;


ALTER FUNCTION public.template_versions_check() OWNER TO dotcms_dev;

--
-- Name: =; Type: OPERATOR; Schema: public; Owner: dotcms_dev
--

CREATE OPERATOR public.= (
    PROCEDURE = public."intBoolResult",
    LEFTARG = boolean,
    RIGHTARG = integer
);


ALTER OPERATOR public.= (boolean, integer) OWNER TO dotcms_dev;

--
-- Name: =; Type: OPERATOR; Schema: public; Owner: dotcms_dev
--

CREATE OPERATOR public.= (
    PROCEDURE = public."boolIntResult",
    LEFTARG = integer,
    RIGHTARG = boolean
);


ALTER OPERATOR public.= (integer, boolean) OWNER TO dotcms_dev;

--
-- Name: =; Type: OPERATOR; Schema: public; Owner: dotcms_dev
--

CREATE OPERATOR public.= (
    PROCEDURE = public."bigIntBoolResult",
    LEFTARG = boolean,
    RIGHTARG = bigint
);


ALTER OPERATOR public.= (boolean, bigint) OWNER TO dotcms_dev;

--
-- Name: =; Type: OPERATOR; Schema: public; Owner: dotcms_dev
--

CREATE OPERATOR public.= (
    PROCEDURE = public."boolBigIntResult",
    LEFTARG = bigint,
    RIGHTARG = boolean
);


ALTER OPERATOR public.= (bigint, boolean) OWNER TO dotcms_dev;

--
-- Name: address; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.address (
    addressid character varying(100) NOT NULL,
    companyid character varying(100) NOT NULL,
    userid character varying(100) NOT NULL,
    username character varying(100),
    createdate timestamp without time zone,
    modifieddate timestamp without time zone,
    classname character varying(100),
    classpk character varying(100),
    description character varying(100),
    street1 character varying(100),
    street2 character varying(100),
    city character varying(100),
    state character varying(100),
    zip character varying(100),
    country character varying(100),
    phone character varying(100),
    fax character varying(100),
    cell character varying(100),
    priority integer
);


ALTER TABLE public.address OWNER TO dotcms_dev;

--
-- Name: adminconfig; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.adminconfig (
    configid character varying(100) NOT NULL,
    companyid character varying(100) NOT NULL,
    type_ character varying(100),
    name character varying(100),
    config text
);


ALTER TABLE public.adminconfig OWNER TO dotcms_dev;

--
-- Name: analytic_summary; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.analytic_summary (
    id bigint NOT NULL,
    summary_period_id bigint NOT NULL,
    host_id character varying(36) NOT NULL,
    visits bigint,
    page_views bigint,
    unique_visits bigint,
    new_visits bigint,
    direct_traffic bigint,
    referring_sites bigint,
    search_engines bigint,
    bounce_rate integer,
    avg_time_on_site timestamp without time zone
);


ALTER TABLE public.analytic_summary OWNER TO dotcms_dev;

--
-- Name: analytic_summary_404; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.analytic_summary_404 (
    id bigint NOT NULL,
    summary_period_id bigint NOT NULL,
    host_id character varying(36),
    uri character varying(255),
    referer_uri character varying(255)
);


ALTER TABLE public.analytic_summary_404 OWNER TO dotcms_dev;

--
-- Name: analytic_summary_content; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.analytic_summary_content (
    id bigint NOT NULL,
    summary_id bigint NOT NULL,
    inode character varying(255),
    hits bigint,
    uri character varying(255),
    title character varying(255)
);


ALTER TABLE public.analytic_summary_content OWNER TO dotcms_dev;

--
-- Name: analytic_summary_pages; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.analytic_summary_pages (
    id bigint NOT NULL,
    summary_id bigint NOT NULL,
    inode character varying(255),
    hits bigint,
    uri character varying(255)
);


ALTER TABLE public.analytic_summary_pages OWNER TO dotcms_dev;

--
-- Name: analytic_summary_period; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.analytic_summary_period (
    id bigint NOT NULL,
    full_date timestamp without time zone,
    day integer,
    week integer,
    month integer,
    year character varying(255),
    dayname character varying(50) NOT NULL,
    monthname character varying(50) NOT NULL
);


ALTER TABLE public.analytic_summary_period OWNER TO dotcms_dev;

--
-- Name: analytic_summary_referer; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.analytic_summary_referer (
    id bigint NOT NULL,
    summary_id bigint NOT NULL,
    hits bigint,
    uri character varying(255)
);


ALTER TABLE public.analytic_summary_referer OWNER TO dotcms_dev;

--
-- Name: analytic_summary_visits; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.analytic_summary_visits (
    id bigint NOT NULL,
    summary_period_id bigint NOT NULL,
    host_id character varying(36),
    visit_time timestamp without time zone,
    visits bigint
);


ALTER TABLE public.analytic_summary_visits OWNER TO dotcms_dev;

--
-- Name: analytic_summary_workstream; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.analytic_summary_workstream (
    id bigint NOT NULL,
    inode character varying(255),
    asset_type character varying(255),
    mod_user_id character varying(255),
    host_id character varying(36),
    mod_date timestamp without time zone,
    action character varying(255),
    name character varying(255)
);


ALTER TABLE public.analytic_summary_workstream OWNER TO dotcms_dev;

--
-- Name: api_token_issued; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.api_token_issued (
    token_id character varying(255) NOT NULL,
    token_userid character varying(255) NOT NULL,
    issue_date timestamp without time zone NOT NULL,
    expire_date timestamp without time zone NOT NULL,
    requested_by_userid character varying(255) NOT NULL,
    requested_by_ip character varying(255) NOT NULL,
    revoke_date timestamp without time zone,
    allowed_from character varying(255),
    issuer character varying(255),
    claims text,
    mod_date timestamp without time zone NOT NULL
);


ALTER TABLE public.api_token_issued OWNER TO dotcms_dev;

--
-- Name: broken_link; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.broken_link (
    id character varying(36) NOT NULL,
    inode character varying(36) NOT NULL,
    field character varying(36) NOT NULL,
    link character varying(255) NOT NULL,
    title character varying(255) NOT NULL,
    status_code integer NOT NULL
);


ALTER TABLE public.broken_link OWNER TO dotcms_dev;

--
-- Name: calendar_reminder; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.calendar_reminder (
    user_id character varying(255) NOT NULL,
    event_id character varying(36) NOT NULL,
    send_date timestamp without time zone NOT NULL
);


ALTER TABLE public.calendar_reminder OWNER TO dotcms_dev;

--
-- Name: campaign; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.campaign (
    inode character varying(36) NOT NULL,
    title character varying(255),
    from_email character varying(255),
    from_name character varying(255),
    subject character varying(255),
    message text,
    user_id character varying(255),
    start_date timestamp without time zone,
    completed_date timestamp without time zone,
    active boolean DEFAULT false,
    locked boolean,
    sends_per_hour character varying(15),
    sendemail boolean,
    communicationinode character varying(36),
    userfilterinode character varying(36),
    sendto character varying(15),
    isrecurrent boolean,
    wassent boolean,
    expiration_date timestamp without time zone,
    parent_campaign character varying(36)
);


ALTER TABLE public.campaign OWNER TO dotcms_dev;

--
-- Name: category; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.category (
    inode character varying(36) NOT NULL,
    category_name character varying(255),
    category_key character varying(255),
    sort_order integer,
    active boolean,
    keywords text,
    category_velocity_var_name character varying(255) NOT NULL,
    mod_date timestamp without time zone
);


ALTER TABLE public.category OWNER TO dotcms_dev;

--
-- Name: chain; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.chain (
    id bigint NOT NULL,
    key_name character varying(255),
    name character varying(255) NOT NULL,
    success_value character varying(255) NOT NULL,
    failure_value character varying(255) NOT NULL
);


ALTER TABLE public.chain OWNER TO dotcms_dev;

--
-- Name: chain_link_code; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.chain_link_code (
    id bigint NOT NULL,
    class_name character varying(255),
    code text NOT NULL,
    last_mod_date timestamp without time zone NOT NULL,
    language character varying(255) NOT NULL
);


ALTER TABLE public.chain_link_code OWNER TO dotcms_dev;

--
-- Name: chain_link_code_seq; Type: SEQUENCE; Schema: public; Owner: dotcms_dev
--

CREATE SEQUENCE public.chain_link_code_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.chain_link_code_seq OWNER TO dotcms_dev;

--
-- Name: chain_seq; Type: SEQUENCE; Schema: public; Owner: dotcms_dev
--

CREATE SEQUENCE public.chain_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.chain_seq OWNER TO dotcms_dev;

--
-- Name: chain_state; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.chain_state (
    id bigint NOT NULL,
    chain_id bigint NOT NULL,
    link_code_id bigint NOT NULL,
    state_order bigint NOT NULL
);


ALTER TABLE public.chain_state OWNER TO dotcms_dev;

--
-- Name: chain_state_parameter; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.chain_state_parameter (
    id bigint NOT NULL,
    chain_state_id bigint NOT NULL,
    name character varying(255) NOT NULL,
    value character varying(255) NOT NULL
);


ALTER TABLE public.chain_state_parameter OWNER TO dotcms_dev;

--
-- Name: chain_state_parameter_seq; Type: SEQUENCE; Schema: public; Owner: dotcms_dev
--

CREATE SEQUENCE public.chain_state_parameter_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.chain_state_parameter_seq OWNER TO dotcms_dev;

--
-- Name: chain_state_seq; Type: SEQUENCE; Schema: public; Owner: dotcms_dev
--

CREATE SEQUENCE public.chain_state_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.chain_state_seq OWNER TO dotcms_dev;

--
-- Name: challenge_question; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.challenge_question (
    cquestionid bigint NOT NULL,
    cqtext character varying(255)
);


ALTER TABLE public.challenge_question OWNER TO dotcms_dev;

--
-- Name: click; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.click (
    inode character varying(36) NOT NULL,
    link character varying(255),
    click_count integer
);


ALTER TABLE public.click OWNER TO dotcms_dev;

--
-- Name: clickstream; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.clickstream (
    clickstream_id bigint NOT NULL,
    cookie_id character varying(255),
    user_id character varying(255),
    start_date timestamp without time zone,
    end_date timestamp without time zone,
    referer character varying(255),
    remote_address character varying(255),
    remote_hostname character varying(255),
    user_agent character varying(255),
    bot boolean,
    host_id character varying(36),
    last_page_id character varying(50),
    first_page_id character varying(50),
    operating_system character varying(50),
    browser_name character varying(50),
    browser_version character varying(50),
    mobile_device boolean,
    number_of_requests integer
);


ALTER TABLE public.clickstream OWNER TO dotcms_dev;

--
-- Name: clickstream_404; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.clickstream_404 (
    clickstream_404_id bigint NOT NULL,
    referer_uri character varying(255),
    query_string text,
    request_uri character varying(255),
    user_id character varying(255),
    host_id character varying(36),
    timestampper timestamp without time zone
);


ALTER TABLE public.clickstream_404 OWNER TO dotcms_dev;

--
-- Name: clickstream_404_seq; Type: SEQUENCE; Schema: public; Owner: dotcms_dev
--

CREATE SEQUENCE public.clickstream_404_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.clickstream_404_seq OWNER TO dotcms_dev;

--
-- Name: clickstream_request; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.clickstream_request (
    clickstream_request_id bigint NOT NULL,
    clickstream_id bigint,
    server_name character varying(255),
    protocol character varying(255),
    server_port integer,
    request_uri character varying(255),
    request_order integer,
    query_string text,
    language_id bigint,
    timestampper timestamp without time zone,
    host_id character varying(36),
    associated_identifier character varying(36)
);


ALTER TABLE public.clickstream_request OWNER TO dotcms_dev;

--
-- Name: clickstream_request_seq; Type: SEQUENCE; Schema: public; Owner: dotcms_dev
--

CREATE SEQUENCE public.clickstream_request_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.clickstream_request_seq OWNER TO dotcms_dev;

--
-- Name: clickstream_seq; Type: SEQUENCE; Schema: public; Owner: dotcms_dev
--

CREATE SEQUENCE public.clickstream_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.clickstream_seq OWNER TO dotcms_dev;

--
-- Name: cluster_server; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.cluster_server (
    server_id character varying(36) NOT NULL,
    cluster_id character varying(36) NOT NULL,
    name character varying(100),
    ip_address character varying(39) NOT NULL,
    host character varying(255),
    cache_port smallint,
    es_transport_tcp_port smallint,
    es_network_port smallint,
    es_http_port smallint,
    key_ character varying(100)
);


ALTER TABLE public.cluster_server OWNER TO dotcms_dev;

--
-- Name: cluster_server_action; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.cluster_server_action (
    server_action_id character varying(36) NOT NULL,
    originator_id character varying(36) NOT NULL,
    server_id character varying(36) NOT NULL,
    failed boolean,
    response character varying(2048),
    action_id character varying(1024) NOT NULL,
    completed boolean,
    entered_date timestamp without time zone NOT NULL,
    time_out_seconds bigint NOT NULL
);


ALTER TABLE public.cluster_server_action OWNER TO dotcms_dev;

--
-- Name: cluster_server_uptime; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.cluster_server_uptime (
    id character varying(36) NOT NULL,
    server_id character varying(36),
    startup timestamp without time zone,
    heartbeat timestamp without time zone
);


ALTER TABLE public.cluster_server_uptime OWNER TO dotcms_dev;

--
-- Name: cms_layout; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.cms_layout (
    id character varying(36) NOT NULL,
    layout_name character varying(255) NOT NULL,
    description character varying(255),
    tab_order integer
);


ALTER TABLE public.cms_layout OWNER TO dotcms_dev;

--
-- Name: cms_layouts_portlets; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.cms_layouts_portlets (
    id character varying(36) NOT NULL,
    layout_id character varying(36) NOT NULL,
    portlet_id character varying(100) NOT NULL,
    portlet_order integer
);


ALTER TABLE public.cms_layouts_portlets OWNER TO dotcms_dev;

--
-- Name: cms_role; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.cms_role (
    id character varying(36) NOT NULL,
    role_name character varying(255) NOT NULL,
    description text,
    role_key character varying(255),
    db_fqn character varying(1000) NOT NULL,
    parent character varying(36) NOT NULL,
    edit_permissions boolean,
    edit_users boolean,
    edit_layouts boolean,
    locked boolean,
    system boolean
);


ALTER TABLE public.cms_role OWNER TO dotcms_dev;

--
-- Name: cms_roles_ir; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.cms_roles_ir (
    name character varying(1000),
    role_key character varying(255),
    local_role_id character varying(36) NOT NULL,
    remote_role_id character varying(36),
    local_role_fqn character varying(1000),
    remote_role_fqn character varying(1000),
    endpoint_id character varying(36) NOT NULL
);


ALTER TABLE public.cms_roles_ir OWNER TO dotcms_dev;

--
-- Name: communication; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.communication (
    inode character varying(36) NOT NULL,
    title character varying(255),
    trackback_link_inode character varying(36),
    communication_type character varying(255),
    from_name character varying(255),
    from_email character varying(255),
    email_subject character varying(255),
    html_page_inode character varying(36),
    text_message text,
    mod_date timestamp without time zone,
    modified_by character varying(255),
    ext_comm_id character varying(255)
);


ALTER TABLE public.communication OWNER TO dotcms_dev;

--
-- Name: company; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.company (
    companyid character varying(100) NOT NULL,
    key_ text,
    portalurl character varying(100) NOT NULL,
    homeurl character varying(100) NOT NULL,
    mx character varying(100) NOT NULL,
    name character varying(100) NOT NULL,
    shortname character varying(100) NOT NULL,
    type_ character varying(100),
    size_ character varying(100),
    street character varying(100),
    city character varying(100),
    state character varying(100),
    zip character varying(100),
    phone character varying(100),
    fax character varying(100),
    emailaddress character varying(100),
    authtype character varying(100),
    autologin boolean,
    strangers boolean
);


ALTER TABLE public.company OWNER TO dotcms_dev;

--
-- Name: container_structures; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.container_structures (
    id character varying(36) NOT NULL,
    container_id character varying(36) NOT NULL,
    container_inode character varying(36) NOT NULL,
    structure_id character varying(36) NOT NULL,
    code text
);


ALTER TABLE public.container_structures OWNER TO dotcms_dev;

--
-- Name: container_version_info; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.container_version_info (
    identifier character varying(36) NOT NULL,
    working_inode character varying(36) NOT NULL,
    live_inode character varying(36),
    deleted boolean NOT NULL,
    locked_by character varying(100),
    locked_on timestamp without time zone,
    version_ts timestamp without time zone NOT NULL
);


ALTER TABLE public.container_version_info OWNER TO dotcms_dev;

--
-- Name: content_rating; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.content_rating (
    id bigint NOT NULL,
    rating real,
    user_id character varying(255),
    session_id character varying(255),
    identifier character varying(36),
    rating_date timestamp without time zone,
    user_ip character varying(255),
    long_live_cookie_id character varying(255)
);


ALTER TABLE public.content_rating OWNER TO dotcms_dev;

--
-- Name: content_rating_sequence; Type: SEQUENCE; Schema: public; Owner: dotcms_dev
--

CREATE SEQUENCE public.content_rating_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.content_rating_sequence OWNER TO dotcms_dev;

--
-- Name: contentlet; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.contentlet (
    inode character varying(36) NOT NULL,
    show_on_menu boolean,
    title character varying(255),
    mod_date timestamp without time zone,
    mod_user character varying(100),
    sort_order integer,
    friendly_name character varying(255),
    structure_inode character varying(36),
    last_review timestamp without time zone,
    next_review timestamp without time zone,
    review_interval character varying(255),
    disabled_wysiwyg character varying(255),
    identifier character varying(36),
    language_id bigint,
    date1 timestamp without time zone,
    date2 timestamp without time zone,
    date3 timestamp without time zone,
    date4 timestamp without time zone,
    date5 timestamp without time zone,
    date6 timestamp without time zone,
    date7 timestamp without time zone,
    date8 timestamp without time zone,
    date9 timestamp without time zone,
    date10 timestamp without time zone,
    date11 timestamp without time zone,
    date12 timestamp without time zone,
    date13 timestamp without time zone,
    date14 timestamp without time zone,
    date15 timestamp without time zone,
    date16 timestamp without time zone,
    date17 timestamp without time zone,
    date18 timestamp without time zone,
    date19 timestamp without time zone,
    date20 timestamp without time zone,
    date21 timestamp without time zone,
    date22 timestamp without time zone,
    date23 timestamp without time zone,
    date24 timestamp without time zone,
    date25 timestamp without time zone,
    text1 character varying(255),
    text2 character varying(255),
    text3 character varying(255),
    text4 character varying(255),
    text5 character varying(255),
    text6 character varying(255),
    text7 character varying(255),
    text8 character varying(255),
    text9 character varying(255),
    text10 character varying(255),
    text11 character varying(255),
    text12 character varying(255),
    text13 character varying(255),
    text14 character varying(255),
    text15 character varying(255),
    text16 character varying(255),
    text17 character varying(255),
    text18 character varying(255),
    text19 character varying(255),
    text20 character varying(255),
    text21 character varying(255),
    text22 character varying(255),
    text23 character varying(255),
    text24 character varying(255),
    text25 character varying(255),
    text_area1 text,
    text_area2 text,
    text_area3 text,
    text_area4 text,
    text_area5 text,
    text_area6 text,
    text_area7 text,
    text_area8 text,
    text_area9 text,
    text_area10 text,
    text_area11 text,
    text_area12 text,
    text_area13 text,
    text_area14 text,
    text_area15 text,
    text_area16 text,
    text_area17 text,
    text_area18 text,
    text_area19 text,
    text_area20 text,
    text_area21 text,
    text_area22 text,
    text_area23 text,
    text_area24 text,
    text_area25 text,
    integer1 bigint,
    integer2 bigint,
    integer3 bigint,
    integer4 bigint,
    integer5 bigint,
    integer6 bigint,
    integer7 bigint,
    integer8 bigint,
    integer9 bigint,
    integer10 bigint,
    integer11 bigint,
    integer12 bigint,
    integer13 bigint,
    integer14 bigint,
    integer15 bigint,
    integer16 bigint,
    integer17 bigint,
    integer18 bigint,
    integer19 bigint,
    integer20 bigint,
    integer21 bigint,
    integer22 bigint,
    integer23 bigint,
    integer24 bigint,
    integer25 bigint,
    float1 real,
    float2 real,
    float3 real,
    float4 real,
    float5 real,
    float6 real,
    float7 real,
    float8 real,
    float9 real,
    float10 real,
    float11 real,
    float12 real,
    float13 real,
    float14 real,
    float15 real,
    float16 real,
    float17 real,
    float18 real,
    float19 real,
    float20 real,
    float21 real,
    float22 real,
    float23 real,
    float24 real,
    float25 real,
    bool1 boolean,
    bool2 boolean,
    bool3 boolean,
    bool4 boolean,
    bool5 boolean,
    bool6 boolean,
    bool7 boolean,
    bool8 boolean,
    bool9 boolean,
    bool10 boolean,
    bool11 boolean,
    bool12 boolean,
    bool13 boolean,
    bool14 boolean,
    bool15 boolean,
    bool16 boolean,
    bool17 boolean,
    bool18 boolean,
    bool19 boolean,
    bool20 boolean,
    bool21 boolean,
    bool22 boolean,
    bool23 boolean,
    bool24 boolean,
    bool25 boolean
);


ALTER TABLE public.contentlet OWNER TO dotcms_dev;

--
-- Name: contentlet_version_info; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.contentlet_version_info (
    identifier character varying(36) NOT NULL,
    lang bigint NOT NULL,
    working_inode character varying(36) NOT NULL,
    live_inode character varying(36),
    deleted boolean NOT NULL,
    locked_by character varying(100),
    locked_on timestamp without time zone,
    version_ts timestamp without time zone NOT NULL
);


ALTER TABLE public.contentlet_version_info OWNER TO dotcms_dev;

--
-- Name: counter; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.counter (
    name character varying(100) NOT NULL,
    currentid integer
);


ALTER TABLE public.counter OWNER TO dotcms_dev;

--
-- Name: dashboard_user_preferences; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.dashboard_user_preferences (
    id bigint NOT NULL,
    summary_404_id bigint,
    user_id character varying(255),
    ignored boolean,
    mod_date timestamp without time zone
);


ALTER TABLE public.dashboard_user_preferences OWNER TO dotcms_dev;

--
-- Name: dashboard_usrpref_seq; Type: SEQUENCE; Schema: public; Owner: dotcms_dev
--

CREATE SEQUENCE public.dashboard_usrpref_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.dashboard_usrpref_seq OWNER TO dotcms_dev;

--
-- Name: db_version; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.db_version (
    db_version integer NOT NULL,
    date_update timestamp with time zone NOT NULL
);


ALTER TABLE public.db_version OWNER TO dotcms_dev;

--
-- Name: dist_journal; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.dist_journal (
    id bigint NOT NULL,
    object_to_index character varying(1024) NOT NULL,
    serverid character varying(64),
    journal_type integer NOT NULL,
    time_entered timestamp without time zone NOT NULL
);


ALTER TABLE public.dist_journal OWNER TO dotcms_dev;

--
-- Name: dist_journal_id_seq; Type: SEQUENCE; Schema: public; Owner: dotcms_dev
--

CREATE SEQUENCE public.dist_journal_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.dist_journal_id_seq OWNER TO dotcms_dev;

--
-- Name: dist_journal_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: dotcms_dev
--

ALTER SEQUENCE public.dist_journal_id_seq OWNED BY public.dist_journal.id;


--
-- Name: dist_process; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.dist_process (
    id bigint NOT NULL,
    object_to_index character varying(1024) NOT NULL,
    serverid character varying(64),
    journal_type integer NOT NULL,
    time_entered timestamp without time zone NOT NULL
);


ALTER TABLE public.dist_process OWNER TO dotcms_dev;

--
-- Name: dist_process_id_seq; Type: SEQUENCE; Schema: public; Owner: dotcms_dev
--

CREATE SEQUENCE public.dist_process_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.dist_process_id_seq OWNER TO dotcms_dev;

--
-- Name: dist_process_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: dotcms_dev
--

ALTER SEQUENCE public.dist_process_id_seq OWNED BY public.dist_process.id;


--
-- Name: dist_reindex_journal_id_seq; Type: SEQUENCE; Schema: public; Owner: dotcms_dev
--

CREATE SEQUENCE public.dist_reindex_journal_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.dist_reindex_journal_id_seq OWNER TO dotcms_dev;

--
-- Name: dist_reindex_journal_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: dotcms_dev
--

ALTER SEQUENCE public.dist_reindex_journal_id_seq OWNED BY public.dist_reindex_journal.id;


--
-- Name: dot_cluster; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.dot_cluster (
    cluster_id character varying(36) NOT NULL
);


ALTER TABLE public.dot_cluster OWNER TO dotcms_dev;

--
-- Name: dot_containers; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.dot_containers (
    inode character varying(36) NOT NULL,
    code text,
    pre_loop text,
    post_loop text,
    show_on_menu boolean,
    title character varying(255),
    mod_date timestamp without time zone,
    mod_user character varying(100),
    sort_order integer,
    friendly_name character varying(255),
    max_contentlets integer,
    use_div boolean,
    staticify boolean,
    sort_contentlets_by character varying(255),
    lucene_query text,
    notes character varying(255),
    identifier character varying(36)
);


ALTER TABLE public.dot_containers OWNER TO dotcms_dev;

--
-- Name: dot_rule; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.dot_rule (
    id character varying(36) NOT NULL,
    name character varying(255) NOT NULL,
    fire_on character varying(20),
    short_circuit boolean DEFAULT false,
    parent_id character varying(36) NOT NULL,
    folder character varying(36) NOT NULL,
    priority integer DEFAULT 0,
    enabled boolean DEFAULT false,
    mod_date timestamp without time zone
);


ALTER TABLE public.dot_rule OWNER TO dotcms_dev;

--
-- Name: field; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.field (
    inode character varying(36) NOT NULL,
    structure_inode character varying(255),
    field_name character varying(255),
    field_type character varying(255),
    field_relation_type character varying(255),
    field_contentlet character varying(255),
    required boolean,
    indexed boolean,
    listed boolean,
    velocity_var_name character varying(255),
    sort_order integer,
    field_values text,
    regex_check character varying(255),
    hint character varying(255),
    default_value character varying(255),
    fixed boolean DEFAULT false NOT NULL,
    read_only boolean DEFAULT false NOT NULL,
    searchable boolean,
    unique_ boolean,
    mod_date timestamp without time zone
);


ALTER TABLE public.field OWNER TO dotcms_dev;

--
-- Name: field_variable; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.field_variable (
    id character varying(36) NOT NULL,
    field_id character varying(36),
    variable_name character varying(255),
    variable_key character varying(255),
    variable_value text,
    user_id character varying(255),
    last_mod_date timestamp without time zone
);


ALTER TABLE public.field_variable OWNER TO dotcms_dev;

--
-- Name: fileassets_ir; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.fileassets_ir (
    file_name character varying(255),
    local_working_inode character varying(36) NOT NULL,
    local_live_inode character varying(36),
    remote_working_inode character varying(36),
    remote_live_inode character varying(36),
    local_identifier character varying(36),
    remote_identifier character varying(36),
    endpoint_id character varying(36) NOT NULL,
    language_id bigint NOT NULL
);


ALTER TABLE public.fileassets_ir OWNER TO dotcms_dev;

--
-- Name: fixes_audit; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.fixes_audit (
    id character varying(36) NOT NULL,
    table_name character varying(255),
    action character varying(255),
    records_altered integer,
    datetime timestamp without time zone
);


ALTER TABLE public.fixes_audit OWNER TO dotcms_dev;

--
-- Name: folder; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.folder (
    inode character varying(36) NOT NULL,
    name character varying(255),
    title character varying(255) NOT NULL,
    show_on_menu boolean,
    sort_order integer,
    files_masks character varying(255),
    identifier character varying(36),
    default_file_type character varying(36),
    mod_date timestamp without time zone
);


ALTER TABLE public.folder OWNER TO dotcms_dev;

--
-- Name: folders_ir; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.folders_ir (
    folder character varying(255),
    local_inode character varying(36) NOT NULL,
    remote_inode character varying(36),
    local_identifier character varying(36),
    remote_identifier character varying(36),
    endpoint_id character varying(36) NOT NULL
);


ALTER TABLE public.folders_ir OWNER TO dotcms_dev;

--
-- Name: host_variable; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.host_variable (
    id character varying(36) NOT NULL,
    host_id character varying(36),
    variable_name character varying(255),
    variable_key character varying(255),
    variable_value character varying(255),
    user_id character varying(255),
    last_mod_date timestamp without time zone
);


ALTER TABLE public.host_variable OWNER TO dotcms_dev;

--
-- Name: htmlpages_ir; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.htmlpages_ir (
    html_page character varying(255),
    local_working_inode character varying(36) NOT NULL,
    local_live_inode character varying(36),
    remote_working_inode character varying(36),
    remote_live_inode character varying(36),
    local_identifier character varying(36),
    remote_identifier character varying(36),
    endpoint_id character varying(36) NOT NULL,
    language_id bigint NOT NULL
);


ALTER TABLE public.htmlpages_ir OWNER TO dotcms_dev;

--
-- Name: image; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.image (
    imageid character varying(200) NOT NULL,
    text_ text NOT NULL
);


ALTER TABLE public.image OWNER TO dotcms_dev;

--
-- Name: import_audit; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.import_audit (
    id bigint NOT NULL,
    start_date timestamp without time zone,
    userid character varying(255),
    filename character varying(512),
    status integer,
    last_inode character varying(100),
    records_to_import bigint,
    serverid character varying(255),
    warnings text,
    errors text,
    results text,
    messages text
);


ALTER TABLE public.import_audit OWNER TO dotcms_dev;

--
-- Name: indicies; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.indicies (
    index_name character varying(30) NOT NULL,
    index_type character varying(16) NOT NULL
);


ALTER TABLE public.indicies OWNER TO dotcms_dev;

--
-- Name: inode; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.inode (
    inode character varying(36) NOT NULL,
    owner character varying(255),
    idate timestamp without time zone,
    type character varying(64)
);


ALTER TABLE public.inode OWNER TO dotcms_dev;

--
-- Name: language; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.language (
    id bigint NOT NULL,
    language_code character varying(5),
    country_code character varying(255),
    language character varying(255),
    country character varying(255)
);


ALTER TABLE public.language OWNER TO dotcms_dev;

--
-- Name: layouts_cms_roles; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.layouts_cms_roles (
    id character varying(36) NOT NULL,
    layout_id character varying(36) NOT NULL,
    role_id character varying(36) NOT NULL
);


ALTER TABLE public.layouts_cms_roles OWNER TO dotcms_dev;

--
-- Name: link_version_info; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.link_version_info (
    identifier character varying(36) NOT NULL,
    working_inode character varying(36) NOT NULL,
    live_inode character varying(36),
    deleted boolean NOT NULL,
    locked_by character varying(100),
    locked_on timestamp without time zone,
    version_ts timestamp without time zone NOT NULL
);


ALTER TABLE public.link_version_info OWNER TO dotcms_dev;

--
-- Name: links; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.links (
    inode character varying(36) NOT NULL,
    show_on_menu boolean,
    title character varying(255),
    mod_date timestamp without time zone,
    mod_user character varying(100),
    sort_order integer,
    friendly_name character varying(255),
    identifier character varying(36),
    protocal character varying(100),
    url character varying(255),
    target character varying(100),
    internal_link_identifier character varying(36),
    link_type character varying(255),
    link_code text
);


ALTER TABLE public.links OWNER TO dotcms_dev;

--
-- Name: log_mapper; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.log_mapper (
    enabled numeric(1,0) NOT NULL,
    log_name character varying(30) NOT NULL,
    description character varying(50) NOT NULL
);


ALTER TABLE public.log_mapper OWNER TO dotcms_dev;

--
-- Name: mailing_list; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.mailing_list (
    inode character varying(36) NOT NULL,
    title character varying(255),
    public_list boolean,
    user_id character varying(255)
);


ALTER TABLE public.mailing_list OWNER TO dotcms_dev;

--
-- Name: multi_tree; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.multi_tree (
    child character varying(36) NOT NULL,
    parent1 character varying(36) NOT NULL,
    parent2 character varying(36) NOT NULL,
    relation_type character varying(64) NOT NULL,
    tree_order integer,
    personalization character varying(255) DEFAULT 'dot:default'::character varying NOT NULL
);


ALTER TABLE public.multi_tree OWNER TO dotcms_dev;

--
-- Name: notification; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.notification (
    group_id character varying(36) NOT NULL,
    user_id character varying(255) NOT NULL,
    message text NOT NULL,
    notification_type character varying(100),
    notification_level character varying(100),
    time_sent timestamp without time zone NOT NULL,
    was_read boolean DEFAULT false
);


ALTER TABLE public.notification OWNER TO dotcms_dev;

--
-- Name: passwordtracker; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.passwordtracker (
    passwordtrackerid character varying(100) NOT NULL,
    userid character varying(100) NOT NULL,
    createdate timestamp without time zone NOT NULL,
    password_ character varying(100) NOT NULL
);


ALTER TABLE public.passwordtracker OWNER TO dotcms_dev;

--
-- Name: permission; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.permission (
    id bigint NOT NULL,
    permission_type character varying(500),
    inode_id character varying(36),
    roleid character varying(36),
    permission integer
);


ALTER TABLE public.permission OWNER TO dotcms_dev;

--
-- Name: permission_reference; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.permission_reference (
    id bigint NOT NULL,
    asset_id character varying(36),
    reference_id character varying(36),
    permission_type character varying(100)
);


ALTER TABLE public.permission_reference OWNER TO dotcms_dev;

--
-- Name: permission_reference_seq; Type: SEQUENCE; Schema: public; Owner: dotcms_dev
--

CREATE SEQUENCE public.permission_reference_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.permission_reference_seq OWNER TO dotcms_dev;

--
-- Name: permission_seq; Type: SEQUENCE; Schema: public; Owner: dotcms_dev
--

CREATE SEQUENCE public.permission_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.permission_seq OWNER TO dotcms_dev;

--
-- Name: plugin; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.plugin (
    id character varying(255) NOT NULL,
    plugin_name character varying(255) NOT NULL,
    plugin_version character varying(255) NOT NULL,
    author character varying(255) NOT NULL,
    first_deployed_date timestamp without time zone NOT NULL,
    last_deployed_date timestamp without time zone NOT NULL
);


ALTER TABLE public.plugin OWNER TO dotcms_dev;

--
-- Name: plugin_property; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.plugin_property (
    plugin_id character varying(255) NOT NULL,
    propkey character varying(255) NOT NULL,
    original_value character varying(255) NOT NULL,
    current_value character varying(255) NOT NULL
);


ALTER TABLE public.plugin_property OWNER TO dotcms_dev;

--
-- Name: pollschoice; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.pollschoice (
    choiceid character varying(100) NOT NULL,
    questionid character varying(100) NOT NULL,
    description text
);


ALTER TABLE public.pollschoice OWNER TO dotcms_dev;

--
-- Name: pollsdisplay; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.pollsdisplay (
    layoutid character varying(100) NOT NULL,
    userid character varying(100) NOT NULL,
    portletid character varying(100) NOT NULL,
    questionid character varying(100) NOT NULL
);


ALTER TABLE public.pollsdisplay OWNER TO dotcms_dev;

--
-- Name: pollsquestion; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.pollsquestion (
    questionid character varying(100) NOT NULL,
    portletid character varying(100) NOT NULL,
    groupid character varying(100) NOT NULL,
    companyid character varying(100) NOT NULL,
    userid character varying(100) NOT NULL,
    username character varying(100),
    createdate timestamp without time zone,
    modifieddate timestamp without time zone,
    title character varying(100),
    description text,
    expirationdate timestamp without time zone,
    lastvotedate timestamp without time zone
);


ALTER TABLE public.pollsquestion OWNER TO dotcms_dev;

--
-- Name: pollsvote; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.pollsvote (
    questionid character varying(100) NOT NULL,
    userid character varying(100) NOT NULL,
    choiceid character varying(100) NOT NULL,
    votedate timestamp without time zone
);


ALTER TABLE public.pollsvote OWNER TO dotcms_dev;

--
-- Name: portlet; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.portlet (
    portletid character varying(100) NOT NULL,
    groupid character varying(100) NOT NULL,
    companyid character varying(100) NOT NULL,
    defaultpreferences text,
    narrow boolean,
    roles text,
    active_ boolean
);


ALTER TABLE public.portlet OWNER TO dotcms_dev;

--
-- Name: portletpreferences; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.portletpreferences (
    portletid character varying(100) NOT NULL,
    userid character varying(100) NOT NULL,
    layoutid character varying(100) NOT NULL,
    preferences text
);


ALTER TABLE public.portletpreferences OWNER TO dotcms_dev;

--
-- Name: publishing_bundle; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.publishing_bundle (
    id character varying(36) NOT NULL,
    name character varying(255) NOT NULL,
    publish_date timestamp without time zone,
    expire_date timestamp without time zone,
    owner character varying(100),
    force_push boolean
);


ALTER TABLE public.publishing_bundle OWNER TO dotcms_dev;

--
-- Name: publishing_bundle_environment; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.publishing_bundle_environment (
    id character varying(36) NOT NULL,
    bundle_id character varying(36) NOT NULL,
    environment_id character varying(36) NOT NULL
);


ALTER TABLE public.publishing_bundle_environment OWNER TO dotcms_dev;

--
-- Name: publishing_end_point; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.publishing_end_point (
    id character varying(36) NOT NULL,
    group_id character varying(700),
    server_name character varying(700),
    address character varying(250),
    port character varying(10),
    protocol character varying(10),
    enabled boolean,
    auth_key text,
    sending boolean
);


ALTER TABLE public.publishing_end_point OWNER TO dotcms_dev;

--
-- Name: publishing_environment; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.publishing_environment (
    id character varying(36) NOT NULL,
    name character varying(255) NOT NULL,
    push_to_all boolean NOT NULL
);


ALTER TABLE public.publishing_environment OWNER TO dotcms_dev;

--
-- Name: publishing_pushed_assets; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.publishing_pushed_assets (
    bundle_id character varying(36) NOT NULL,
    asset_id character varying(36) NOT NULL,
    asset_type character varying(255) NOT NULL,
    push_date timestamp without time zone,
    environment_id character varying(36) NOT NULL,
    endpoint_ids text,
    publisher text
);


ALTER TABLE public.publishing_pushed_assets OWNER TO dotcms_dev;

--
-- Name: publishing_queue; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.publishing_queue (
    id bigint NOT NULL,
    operation bigint,
    asset character varying(2000) NOT NULL,
    language_id bigint NOT NULL,
    entered_date timestamp without time zone,
    publish_date timestamp without time zone,
    type character varying(256),
    bundle_id character varying(256)
);


ALTER TABLE public.publishing_queue OWNER TO dotcms_dev;

--
-- Name: publishing_queue_audit; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.publishing_queue_audit (
    bundle_id character varying(256) NOT NULL,
    status integer,
    status_pojo text,
    status_updated timestamp without time zone,
    create_date timestamp without time zone
);


ALTER TABLE public.publishing_queue_audit OWNER TO dotcms_dev;

--
-- Name: publishing_queue_id_seq; Type: SEQUENCE; Schema: public; Owner: dotcms_dev
--

CREATE SEQUENCE public.publishing_queue_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.publishing_queue_id_seq OWNER TO dotcms_dev;

--
-- Name: publishing_queue_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: dotcms_dev
--

ALTER SEQUENCE public.publishing_queue_id_seq OWNED BY public.publishing_queue.id;


--
-- Name: qrtz_blob_triggers; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.qrtz_blob_triggers (
    trigger_name character varying(80) NOT NULL,
    trigger_group character varying(80) NOT NULL,
    blob_data bytea
);


ALTER TABLE public.qrtz_blob_triggers OWNER TO dotcms_dev;

--
-- Name: qrtz_calendars; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.qrtz_calendars (
    calendar_name character varying(80) NOT NULL,
    calendar bytea NOT NULL
);


ALTER TABLE public.qrtz_calendars OWNER TO dotcms_dev;

--
-- Name: qrtz_cron_triggers; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.qrtz_cron_triggers (
    trigger_name character varying(80) NOT NULL,
    trigger_group character varying(80) NOT NULL,
    cron_expression character varying(80) NOT NULL,
    time_zone_id character varying(80)
);


ALTER TABLE public.qrtz_cron_triggers OWNER TO dotcms_dev;

--
-- Name: qrtz_excl_blob_triggers; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.qrtz_excl_blob_triggers (
    trigger_name character varying(80) NOT NULL,
    trigger_group character varying(80) NOT NULL,
    blob_data bytea
);


ALTER TABLE public.qrtz_excl_blob_triggers OWNER TO dotcms_dev;

--
-- Name: qrtz_excl_calendars; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.qrtz_excl_calendars (
    calendar_name character varying(80) NOT NULL,
    calendar bytea NOT NULL
);


ALTER TABLE public.qrtz_excl_calendars OWNER TO dotcms_dev;

--
-- Name: qrtz_excl_cron_triggers; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.qrtz_excl_cron_triggers (
    trigger_name character varying(80) NOT NULL,
    trigger_group character varying(80) NOT NULL,
    cron_expression character varying(80) NOT NULL,
    time_zone_id character varying(80)
);


ALTER TABLE public.qrtz_excl_cron_triggers OWNER TO dotcms_dev;

--
-- Name: qrtz_excl_fired_triggers; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.qrtz_excl_fired_triggers (
    entry_id character varying(95) NOT NULL,
    trigger_name character varying(80) NOT NULL,
    trigger_group character varying(80) NOT NULL,
    is_volatile boolean NOT NULL,
    instance_name character varying(80) NOT NULL,
    fired_time bigint NOT NULL,
    priority integer NOT NULL,
    state character varying(16) NOT NULL,
    job_name character varying(80),
    job_group character varying(80),
    is_stateful boolean,
    requests_recovery boolean
);


ALTER TABLE public.qrtz_excl_fired_triggers OWNER TO dotcms_dev;

--
-- Name: qrtz_excl_job_details; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.qrtz_excl_job_details (
    job_name character varying(80) NOT NULL,
    job_group character varying(80) NOT NULL,
    description character varying(120),
    job_class_name character varying(128) NOT NULL,
    is_durable boolean NOT NULL,
    is_volatile boolean NOT NULL,
    is_stateful boolean NOT NULL,
    requests_recovery boolean NOT NULL,
    job_data bytea
);


ALTER TABLE public.qrtz_excl_job_details OWNER TO dotcms_dev;

--
-- Name: qrtz_excl_job_listeners; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.qrtz_excl_job_listeners (
    job_name character varying(80) NOT NULL,
    job_group character varying(80) NOT NULL,
    job_listener character varying(80) NOT NULL
);


ALTER TABLE public.qrtz_excl_job_listeners OWNER TO dotcms_dev;

--
-- Name: qrtz_excl_locks; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.qrtz_excl_locks (
    lock_name character varying(40) NOT NULL
);


ALTER TABLE public.qrtz_excl_locks OWNER TO dotcms_dev;

--
-- Name: qrtz_excl_paused_trigger_grps; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.qrtz_excl_paused_trigger_grps (
    trigger_group character varying(80) NOT NULL
);


ALTER TABLE public.qrtz_excl_paused_trigger_grps OWNER TO dotcms_dev;

--
-- Name: qrtz_excl_scheduler_state; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.qrtz_excl_scheduler_state (
    instance_name character varying(80) NOT NULL,
    last_checkin_time bigint NOT NULL,
    checkin_interval bigint NOT NULL
);


ALTER TABLE public.qrtz_excl_scheduler_state OWNER TO dotcms_dev;

--
-- Name: qrtz_excl_simple_triggers; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.qrtz_excl_simple_triggers (
    trigger_name character varying(80) NOT NULL,
    trigger_group character varying(80) NOT NULL,
    repeat_count bigint NOT NULL,
    repeat_interval bigint NOT NULL,
    times_triggered bigint NOT NULL
);


ALTER TABLE public.qrtz_excl_simple_triggers OWNER TO dotcms_dev;

--
-- Name: qrtz_excl_trigger_listeners; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.qrtz_excl_trigger_listeners (
    trigger_name character varying(80) NOT NULL,
    trigger_group character varying(80) NOT NULL,
    trigger_listener character varying(80) NOT NULL
);


ALTER TABLE public.qrtz_excl_trigger_listeners OWNER TO dotcms_dev;

--
-- Name: qrtz_excl_triggers; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.qrtz_excl_triggers (
    trigger_name character varying(80) NOT NULL,
    trigger_group character varying(80) NOT NULL,
    job_name character varying(80) NOT NULL,
    job_group character varying(80) NOT NULL,
    is_volatile boolean NOT NULL,
    description character varying(120),
    next_fire_time bigint,
    prev_fire_time bigint,
    priority integer,
    trigger_state character varying(16) NOT NULL,
    trigger_type character varying(8) NOT NULL,
    start_time bigint NOT NULL,
    end_time bigint,
    calendar_name character varying(80),
    misfire_instr smallint,
    job_data bytea
);


ALTER TABLE public.qrtz_excl_triggers OWNER TO dotcms_dev;

--
-- Name: qrtz_fired_triggers; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.qrtz_fired_triggers (
    entry_id character varying(95) NOT NULL,
    trigger_name character varying(80) NOT NULL,
    trigger_group character varying(80) NOT NULL,
    is_volatile boolean NOT NULL,
    instance_name character varying(80) NOT NULL,
    fired_time bigint NOT NULL,
    priority integer NOT NULL,
    state character varying(16) NOT NULL,
    job_name character varying(80),
    job_group character varying(80),
    is_stateful boolean,
    requests_recovery boolean
);


ALTER TABLE public.qrtz_fired_triggers OWNER TO dotcms_dev;

--
-- Name: qrtz_job_details; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.qrtz_job_details (
    job_name character varying(80) NOT NULL,
    job_group character varying(80) NOT NULL,
    description character varying(120),
    job_class_name character varying(128) NOT NULL,
    is_durable boolean NOT NULL,
    is_volatile boolean NOT NULL,
    is_stateful boolean NOT NULL,
    requests_recovery boolean NOT NULL,
    job_data bytea
);


ALTER TABLE public.qrtz_job_details OWNER TO dotcms_dev;

--
-- Name: qrtz_job_listeners; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.qrtz_job_listeners (
    job_name character varying(80) NOT NULL,
    job_group character varying(80) NOT NULL,
    job_listener character varying(80) NOT NULL
);


ALTER TABLE public.qrtz_job_listeners OWNER TO dotcms_dev;

--
-- Name: qrtz_locks; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.qrtz_locks (
    lock_name character varying(40) NOT NULL
);


ALTER TABLE public.qrtz_locks OWNER TO dotcms_dev;

--
-- Name: qrtz_paused_trigger_grps; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.qrtz_paused_trigger_grps (
    trigger_group character varying(80) NOT NULL
);


ALTER TABLE public.qrtz_paused_trigger_grps OWNER TO dotcms_dev;

--
-- Name: qrtz_scheduler_state; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.qrtz_scheduler_state (
    instance_name character varying(80) NOT NULL,
    last_checkin_time bigint NOT NULL,
    checkin_interval bigint NOT NULL
);


ALTER TABLE public.qrtz_scheduler_state OWNER TO dotcms_dev;

--
-- Name: qrtz_simple_triggers; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.qrtz_simple_triggers (
    trigger_name character varying(80) NOT NULL,
    trigger_group character varying(80) NOT NULL,
    repeat_count bigint NOT NULL,
    repeat_interval bigint NOT NULL,
    times_triggered bigint NOT NULL
);


ALTER TABLE public.qrtz_simple_triggers OWNER TO dotcms_dev;

--
-- Name: qrtz_trigger_listeners; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.qrtz_trigger_listeners (
    trigger_name character varying(80) NOT NULL,
    trigger_group character varying(80) NOT NULL,
    trigger_listener character varying(80) NOT NULL
);


ALTER TABLE public.qrtz_trigger_listeners OWNER TO dotcms_dev;

--
-- Name: qrtz_triggers; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.qrtz_triggers (
    trigger_name character varying(80) NOT NULL,
    trigger_group character varying(80) NOT NULL,
    job_name character varying(80) NOT NULL,
    job_group character varying(80) NOT NULL,
    is_volatile boolean NOT NULL,
    description character varying(120),
    next_fire_time bigint,
    prev_fire_time bigint,
    priority integer,
    trigger_state character varying(16) NOT NULL,
    trigger_type character varying(8) NOT NULL,
    start_time bigint NOT NULL,
    end_time bigint,
    calendar_name character varying(80),
    misfire_instr smallint,
    job_data bytea
);


ALTER TABLE public.qrtz_triggers OWNER TO dotcms_dev;

--
-- Name: quartz_log; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.quartz_log (
    id bigint NOT NULL,
    job_name character varying(255) NOT NULL,
    serverid character varying(64),
    time_started timestamp without time zone NOT NULL
);


ALTER TABLE public.quartz_log OWNER TO dotcms_dev;

--
-- Name: quartz_log_id_seq; Type: SEQUENCE; Schema: public; Owner: dotcms_dev
--

CREATE SEQUENCE public.quartz_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.quartz_log_id_seq OWNER TO dotcms_dev;

--
-- Name: quartz_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: dotcms_dev
--

ALTER SEQUENCE public.quartz_log_id_seq OWNED BY public.quartz_log.id;


--
-- Name: recipient; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.recipient (
    inode character varying(36) NOT NULL,
    name character varying(255),
    lastname character varying(255),
    email character varying(255),
    sent timestamp without time zone,
    opened timestamp without time zone,
    last_result integer,
    last_message character varying(255),
    user_id character varying(100)
);


ALTER TABLE public.recipient OWNER TO dotcms_dev;

--
-- Name: relationship; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.relationship (
    inode character varying(36) NOT NULL,
    parent_structure_inode character varying(255),
    child_structure_inode character varying(255),
    parent_relation_name character varying(255),
    child_relation_name character varying(255),
    relation_type_value character varying(255),
    cardinality integer,
    parent_required boolean,
    child_required boolean,
    fixed boolean
);


ALTER TABLE public.relationship OWNER TO dotcms_dev;

--
-- Name: release_; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.release_ (
    releaseid character varying(100) NOT NULL,
    createdate timestamp without time zone,
    modifieddate timestamp without time zone,
    buildnumber integer,
    builddate timestamp without time zone
);


ALTER TABLE public.release_ OWNER TO dotcms_dev;

--
-- Name: report_asset; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.report_asset (
    inode character varying(36) NOT NULL,
    report_name character varying(255) NOT NULL,
    report_description character varying(1000) NOT NULL,
    requires_input boolean,
    ds character varying(100) NOT NULL,
    web_form_report boolean
);


ALTER TABLE public.report_asset OWNER TO dotcms_dev;

--
-- Name: report_parameter; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.report_parameter (
    inode character varying(36) NOT NULL,
    report_inode character varying(36),
    parameter_description character varying(1000),
    parameter_name character varying(255),
    class_type character varying(250),
    default_value character varying(4000)
);


ALTER TABLE public.report_parameter OWNER TO dotcms_dev;

--
-- Name: rule_action; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.rule_action (
    id character varying(36) NOT NULL,
    rule_id character varying(36),
    priority integer DEFAULT 0,
    actionlet text NOT NULL,
    mod_date timestamp without time zone
);


ALTER TABLE public.rule_action OWNER TO dotcms_dev;

--
-- Name: rule_action_pars; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.rule_action_pars (
    id character varying(36) NOT NULL,
    rule_action_id character varying(36),
    paramkey character varying(255) NOT NULL,
    value text
);


ALTER TABLE public.rule_action_pars OWNER TO dotcms_dev;

--
-- Name: rule_condition; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.rule_condition (
    id character varying(36) NOT NULL,
    conditionlet text NOT NULL,
    condition_group character varying(36),
    comparison character varying(36) NOT NULL,
    operator character varying(10) NOT NULL,
    priority integer DEFAULT 0,
    mod_date timestamp without time zone
);


ALTER TABLE public.rule_condition OWNER TO dotcms_dev;

--
-- Name: rule_condition_group; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.rule_condition_group (
    id character varying(36) NOT NULL,
    rule_id character varying(36),
    operator character varying(10) NOT NULL,
    priority integer DEFAULT 0,
    mod_date timestamp without time zone
);


ALTER TABLE public.rule_condition_group OWNER TO dotcms_dev;

--
-- Name: rule_condition_value; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.rule_condition_value (
    id character varying(36) NOT NULL,
    condition_id character varying(36),
    paramkey character varying(255) NOT NULL,
    value text,
    priority integer DEFAULT 0
);


ALTER TABLE public.rule_condition_value OWNER TO dotcms_dev;

--
-- Name: schemes_ir; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.schemes_ir (
    name character varying(255),
    local_inode character varying(36) NOT NULL,
    remote_inode character varying(36),
    endpoint_id character varying(36) NOT NULL
);


ALTER TABLE public.schemes_ir OWNER TO dotcms_dev;

--
-- Name: sitelic; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.sitelic (
    id character varying(36) NOT NULL,
    serverid character varying(100),
    license text NOT NULL,
    lastping timestamp without time zone NOT NULL
);


ALTER TABLE public.sitelic OWNER TO dotcms_dev;

--
-- Name: sitesearch_audit; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.sitesearch_audit (
    job_id character varying(36) NOT NULL,
    job_name character varying(255) NOT NULL,
    fire_date timestamp without time zone NOT NULL,
    incremental boolean NOT NULL,
    start_date timestamp without time zone,
    end_date timestamp without time zone,
    host_list character varying(500) NOT NULL,
    all_hosts boolean NOT NULL,
    lang_list character varying(500) NOT NULL,
    path character varying(500) NOT NULL,
    path_include boolean NOT NULL,
    files_count integer NOT NULL,
    pages_count integer NOT NULL,
    urlmaps_count integer NOT NULL,
    index_name character varying(100) NOT NULL
);


ALTER TABLE public.sitesearch_audit OWNER TO dotcms_dev;

--
-- Name: structure; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.structure (
    inode character varying(36) NOT NULL,
    name character varying(255),
    description character varying(255),
    default_structure boolean,
    review_interval character varying(255),
    reviewer_role character varying(255),
    page_detail character varying(36),
    structuretype integer,
    system boolean,
    fixed boolean DEFAULT false NOT NULL,
    velocity_var_name character varying(255) NOT NULL,
    url_map_pattern character varying(512),
    host character varying(36) DEFAULT 'SYSTEM_HOST'::character varying NOT NULL,
    folder character varying(36) DEFAULT 'SYSTEM_FOLDER'::character varying NOT NULL,
    expire_date_var character varying(255),
    publish_date_var character varying(255),
    mod_date timestamp without time zone
);


ALTER TABLE public.structure OWNER TO dotcms_dev;

--
-- Name: structures_ir; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.structures_ir (
    velocity_name character varying(255),
    local_inode character varying(36) NOT NULL,
    remote_inode character varying(36),
    endpoint_id character varying(36) NOT NULL
);


ALTER TABLE public.structures_ir OWNER TO dotcms_dev;

--
-- Name: summary_404_seq; Type: SEQUENCE; Schema: public; Owner: dotcms_dev
--

CREATE SEQUENCE public.summary_404_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.summary_404_seq OWNER TO dotcms_dev;

--
-- Name: summary_content_seq; Type: SEQUENCE; Schema: public; Owner: dotcms_dev
--

CREATE SEQUENCE public.summary_content_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.summary_content_seq OWNER TO dotcms_dev;

--
-- Name: summary_pages_seq; Type: SEQUENCE; Schema: public; Owner: dotcms_dev
--

CREATE SEQUENCE public.summary_pages_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.summary_pages_seq OWNER TO dotcms_dev;

--
-- Name: summary_period_seq; Type: SEQUENCE; Schema: public; Owner: dotcms_dev
--

CREATE SEQUENCE public.summary_period_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.summary_period_seq OWNER TO dotcms_dev;

--
-- Name: summary_referer_seq; Type: SEQUENCE; Schema: public; Owner: dotcms_dev
--

CREATE SEQUENCE public.summary_referer_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.summary_referer_seq OWNER TO dotcms_dev;

--
-- Name: summary_seq; Type: SEQUENCE; Schema: public; Owner: dotcms_dev
--

CREATE SEQUENCE public.summary_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.summary_seq OWNER TO dotcms_dev;

--
-- Name: summary_visits_seq; Type: SEQUENCE; Schema: public; Owner: dotcms_dev
--

CREATE SEQUENCE public.summary_visits_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.summary_visits_seq OWNER TO dotcms_dev;

--
-- Name: system_event; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.system_event (
    identifier character varying(36) NOT NULL,
    event_type character varying(50) NOT NULL,
    payload text NOT NULL,
    created bigint NOT NULL,
    server_id character varying(36) NOT NULL
);


ALTER TABLE public.system_event OWNER TO dotcms_dev;

--
-- Name: tag; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.tag (
    tag_id character varying(100) NOT NULL,
    tagname character varying(255) NOT NULL,
    host_id character varying(255) DEFAULT 'SYSTEM_HOST'::character varying,
    user_id text,
    persona boolean DEFAULT false,
    mod_date timestamp without time zone
);


ALTER TABLE public.tag OWNER TO dotcms_dev;

--
-- Name: tag_inode; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.tag_inode (
    tag_id character varying(100) NOT NULL,
    inode character varying(100) NOT NULL,
    field_var_name character varying(255),
    mod_date timestamp without time zone
);


ALTER TABLE public.tag_inode OWNER TO dotcms_dev;

--
-- Name: template; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.template (
    inode character varying(36) NOT NULL,
    show_on_menu boolean,
    title character varying(255),
    mod_date timestamp without time zone,
    mod_user character varying(100),
    sort_order integer,
    friendly_name character varying(255),
    body text,
    header text,
    footer text,
    image character varying(36),
    identifier character varying(36),
    drawed boolean,
    drawed_body text,
    add_container_links integer,
    containers_added integer,
    head_code text,
    theme character varying(255)
);


ALTER TABLE public.template OWNER TO dotcms_dev;

--
-- Name: template_containers; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.template_containers (
    id character varying(36) NOT NULL,
    template_id character varying(36) NOT NULL,
    container_id character varying(36) NOT NULL
);


ALTER TABLE public.template_containers OWNER TO dotcms_dev;

--
-- Name: template_version_info; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.template_version_info (
    identifier character varying(36) NOT NULL,
    working_inode character varying(36) NOT NULL,
    live_inode character varying(36),
    deleted boolean NOT NULL,
    locked_by character varying(100),
    locked_on timestamp without time zone,
    version_ts timestamp without time zone NOT NULL
);


ALTER TABLE public.template_version_info OWNER TO dotcms_dev;

--
-- Name: trackback; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.trackback (
    id bigint NOT NULL,
    asset_identifier character varying(36),
    title character varying(255),
    excerpt character varying(255),
    url character varying(255),
    blog_name character varying(255),
    track_date timestamp without time zone NOT NULL
);


ALTER TABLE public.trackback OWNER TO dotcms_dev;

--
-- Name: trackback_sequence; Type: SEQUENCE; Schema: public; Owner: dotcms_dev
--

CREATE SEQUENCE public.trackback_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.trackback_sequence OWNER TO dotcms_dev;

--
-- Name: tree; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.tree (
    child character varying(36) NOT NULL,
    parent character varying(36) NOT NULL,
    relation_type character varying(64) NOT NULL,
    tree_order integer
);


ALTER TABLE public.tree OWNER TO dotcms_dev;

--
-- Name: user_; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.user_ (
    userid character varying(100) NOT NULL,
    companyid character varying(100) NOT NULL,
    createdate timestamp without time zone,
    mod_date timestamp without time zone,
    password_ text,
    passwordencrypted boolean,
    passwordexpirationdate timestamp without time zone,
    passwordreset boolean,
    firstname character varying(100),
    middlename character varying(100),
    lastname character varying(100),
    nickname character varying(100),
    male boolean,
    birthday timestamp without time zone,
    emailaddress character varying(100),
    smsid character varying(100),
    aimid character varying(100),
    icqid character varying(100),
    msnid character varying(100),
    ymid character varying(100),
    favoriteactivity character varying(100),
    favoritebibleverse character varying(100),
    favoritefood character varying(100),
    favoritemovie character varying(100),
    favoritemusic character varying(100),
    languageid character varying(100),
    timezoneid character varying(100),
    skinid character varying(100),
    dottedskins boolean,
    roundedskins boolean,
    greeting character varying(100),
    resolution character varying(100),
    refreshrate character varying(100),
    layoutids character varying(100),
    comments text,
    logindate timestamp without time zone,
    loginip character varying(100),
    lastlogindate timestamp without time zone,
    lastloginip character varying(100),
    failedloginattempts integer,
    agreedtotermsofuse boolean,
    active_ boolean,
    delete_in_progress boolean DEFAULT false,
    delete_date timestamp without time zone
);


ALTER TABLE public.user_ OWNER TO dotcms_dev;

--
-- Name: user_comments; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.user_comments (
    inode character varying(36) NOT NULL,
    user_id character varying(255),
    cdate timestamp without time zone,
    comment_user_id character varying(100),
    type character varying(255),
    method character varying(255),
    subject character varying(255),
    ucomment text,
    communication_id character varying(36)
);


ALTER TABLE public.user_comments OWNER TO dotcms_dev;

--
-- Name: user_filter; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.user_filter (
    inode character varying(36) NOT NULL,
    title character varying(255),
    firstname character varying(100),
    middlename character varying(100),
    lastname character varying(100),
    emailaddress character varying(100),
    birthdaytypesearch character varying(100),
    birthday timestamp without time zone,
    birthdayfrom timestamp without time zone,
    birthdayto timestamp without time zone,
    lastlogintypesearch character varying(100),
    lastloginsince character varying(100),
    loginfrom timestamp without time zone,
    loginto timestamp without time zone,
    createdtypesearch character varying(100),
    createdsince character varying(100),
    createdfrom timestamp without time zone,
    createdto timestamp without time zone,
    lastvisittypesearch character varying(100),
    lastvisitsince character varying(100),
    lastvisitfrom timestamp without time zone,
    lastvisitto timestamp without time zone,
    city character varying(100),
    state character varying(100),
    country character varying(100),
    zip character varying(100),
    cell character varying(100),
    phone character varying(100),
    fax character varying(100),
    active_ character varying(255),
    tagname character varying(255),
    var1 character varying(255),
    var2 character varying(255),
    var3 character varying(255),
    var4 character varying(255),
    var5 character varying(255),
    var6 character varying(255),
    var7 character varying(255),
    var8 character varying(255),
    var9 character varying(255),
    var10 character varying(255),
    var11 character varying(255),
    var12 character varying(255),
    var13 character varying(255),
    var14 character varying(255),
    var15 character varying(255),
    var16 character varying(255),
    var17 character varying(255),
    var18 character varying(255),
    var19 character varying(255),
    var20 character varying(255),
    var21 character varying(255),
    var22 character varying(255),
    var23 character varying(255),
    var24 character varying(255),
    var25 character varying(255),
    categories character varying(255)
);


ALTER TABLE public.user_filter OWNER TO dotcms_dev;

--
-- Name: user_preferences; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.user_preferences (
    id bigint NOT NULL,
    user_id character varying(100) NOT NULL,
    preference character varying(255),
    pref_value text
);


ALTER TABLE public.user_preferences OWNER TO dotcms_dev;

--
-- Name: user_preferences_seq; Type: SEQUENCE; Schema: public; Owner: dotcms_dev
--

CREATE SEQUENCE public.user_preferences_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_preferences_seq OWNER TO dotcms_dev;

--
-- Name: user_proxy; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.user_proxy (
    inode character varying(36) NOT NULL,
    user_id character varying(255),
    prefix character varying(255),
    suffix character varying(255),
    title character varying(255),
    school character varying(255),
    how_heard character varying(255),
    company character varying(255),
    long_lived_cookie character varying(255),
    website character varying(255),
    graduation_year integer,
    organization character varying(255),
    mail_subscription boolean,
    var1 character varying(255),
    var2 character varying(255),
    var3 character varying(255),
    var4 character varying(255),
    var5 character varying(255),
    var6 character varying(255),
    var7 character varying(255),
    var8 character varying(255),
    var9 character varying(255),
    var10 character varying(255),
    var11 character varying(255),
    var12 character varying(255),
    var13 character varying(255),
    var14 character varying(255),
    var15 character varying(255),
    var16 character varying(255),
    var17 character varying(255),
    var18 character varying(255),
    var19 character varying(255),
    var20 character varying(255),
    var21 character varying(255),
    var22 character varying(255),
    var23 character varying(255),
    var24 character varying(255),
    var25 character varying(255),
    last_result integer,
    last_message character varying(255),
    no_click_tracking boolean,
    cquestionid character varying(255),
    cqanswer character varying(255),
    chapter_officer character varying(255)
);


ALTER TABLE public.user_proxy OWNER TO dotcms_dev;

--
-- Name: user_to_delete_seq; Type: SEQUENCE; Schema: public; Owner: dotcms_dev
--

CREATE SEQUENCE public.user_to_delete_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_to_delete_seq OWNER TO dotcms_dev;

--
-- Name: users_cms_roles; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.users_cms_roles (
    id character varying(36) NOT NULL,
    user_id character varying(100) NOT NULL,
    role_id character varying(36) NOT NULL
);


ALTER TABLE public.users_cms_roles OWNER TO dotcms_dev;

--
-- Name: users_to_delete; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.users_to_delete (
    id bigint NOT NULL,
    user_id character varying(255)
);


ALTER TABLE public.users_to_delete OWNER TO dotcms_dev;

--
-- Name: usertracker; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.usertracker (
    usertrackerid character varying(100) NOT NULL,
    companyid character varying(100) NOT NULL,
    userid character varying(100) NOT NULL,
    modifieddate timestamp without time zone,
    remoteaddr character varying(100),
    remotehost character varying(100),
    useragent character varying(100)
);


ALTER TABLE public.usertracker OWNER TO dotcms_dev;

--
-- Name: usertrackerpath; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.usertrackerpath (
    usertrackerpathid character varying(100) NOT NULL,
    usertrackerid character varying(100) NOT NULL,
    path text NOT NULL,
    pathdate timestamp without time zone NOT NULL
);


ALTER TABLE public.usertrackerpath OWNER TO dotcms_dev;

--
-- Name: web_form; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.web_form (
    web_form_id character varying(36) NOT NULL,
    form_type character varying(255),
    submit_date timestamp without time zone,
    prefix character varying(255),
    first_name character varying(255),
    middle_initial character varying(255),
    middle_name character varying(255),
    full_name character varying(255),
    organization character varying(255),
    title character varying(255),
    last_name character varying(255),
    address character varying(255),
    address1 character varying(255),
    address2 character varying(255),
    city character varying(255),
    state character varying(255),
    zip character varying(255),
    country character varying(255),
    phone character varying(255),
    email character varying(255),
    custom_fields text,
    user_inode character varying(100),
    categories character varying(255)
);


ALTER TABLE public.web_form OWNER TO dotcms_dev;

--
-- Name: workflow_action; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.workflow_action (
    id character varying(36) NOT NULL,
    step_id character varying(36),
    name character varying(255) NOT NULL,
    condition_to_progress text,
    next_step_id character varying(36),
    next_assign character varying(36) NOT NULL,
    my_order integer DEFAULT 0,
    assignable boolean DEFAULT false,
    commentable boolean DEFAULT false,
    requires_checkout boolean DEFAULT false,
    icon character varying(255) DEFAULT 'defaultWfIcon'::character varying,
    show_on character varying(255) DEFAULT 'LOCKED,UNLOCKED'::character varying,
    use_role_hierarchy_assign boolean DEFAULT false,
    scheme_id character varying(36) NOT NULL
);


ALTER TABLE public.workflow_action OWNER TO dotcms_dev;

--
-- Name: workflow_action_class; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.workflow_action_class (
    id character varying(36) NOT NULL,
    action_id character varying(36),
    name character varying(255) NOT NULL,
    my_order integer DEFAULT 0,
    clazz text
);


ALTER TABLE public.workflow_action_class OWNER TO dotcms_dev;

--
-- Name: workflow_action_class_pars; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.workflow_action_class_pars (
    id character varying(36) NOT NULL,
    workflow_action_class_id character varying(36),
    key character varying(255) NOT NULL,
    value text
);


ALTER TABLE public.workflow_action_class_pars OWNER TO dotcms_dev;

--
-- Name: workflow_action_mappings; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.workflow_action_mappings (
    id character varying(36) NOT NULL,
    action character varying(36) NOT NULL,
    workflow_action character varying(255) NOT NULL,
    scheme_or_content_type character varying(255) NOT NULL
);


ALTER TABLE public.workflow_action_mappings OWNER TO dotcms_dev;

--
-- Name: workflow_action_step; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.workflow_action_step (
    action_id character varying(36) NOT NULL,
    step_id character varying(36) NOT NULL,
    action_order integer DEFAULT 0
);


ALTER TABLE public.workflow_action_step OWNER TO dotcms_dev;

--
-- Name: workflow_comment; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.workflow_comment (
    id character varying(36) NOT NULL,
    creation_date timestamp without time zone,
    posted_by character varying(255),
    wf_comment text,
    workflowtask_id character varying(36)
);


ALTER TABLE public.workflow_comment OWNER TO dotcms_dev;

--
-- Name: workflow_history; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.workflow_history (
    id character varying(36) NOT NULL,
    creation_date timestamp without time zone,
    made_by character varying(255),
    change_desc text,
    workflowtask_id character varying(36),
    workflow_action_id character varying(36),
    workflow_step_id character varying(36)
);


ALTER TABLE public.workflow_history OWNER TO dotcms_dev;

--
-- Name: workflow_scheme; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.workflow_scheme (
    id character varying(36) NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    archived boolean DEFAULT false,
    mandatory boolean DEFAULT false,
    default_scheme boolean DEFAULT false,
    entry_action_id character varying(36),
    mod_date timestamp without time zone
);


ALTER TABLE public.workflow_scheme OWNER TO dotcms_dev;

--
-- Name: workflow_scheme_x_structure; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.workflow_scheme_x_structure (
    id character varying(36) NOT NULL,
    scheme_id character varying(36),
    structure_id character varying(36)
);


ALTER TABLE public.workflow_scheme_x_structure OWNER TO dotcms_dev;

--
-- Name: workflow_step; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.workflow_step (
    id character varying(36) NOT NULL,
    name character varying(255) NOT NULL,
    scheme_id character varying(36),
    my_order integer DEFAULT 0,
    resolved boolean DEFAULT false,
    escalation_enable boolean DEFAULT false,
    escalation_action character varying(36),
    escalation_time integer DEFAULT 0
);


ALTER TABLE public.workflow_step OWNER TO dotcms_dev;

--
-- Name: workflow_task; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.workflow_task (
    id character varying(36) NOT NULL,
    creation_date timestamp without time zone,
    mod_date timestamp without time zone,
    due_date timestamp without time zone,
    created_by character varying(255),
    assigned_to character varying(255),
    belongs_to character varying(255),
    title character varying(255),
    description text,
    status character varying(255),
    webasset character varying(255),
    language_id bigint
);


ALTER TABLE public.workflow_task OWNER TO dotcms_dev;

--
-- Name: workflowtask_files; Type: TABLE; Schema: public; Owner: dotcms_dev
--

CREATE TABLE public.workflowtask_files (
    id character varying(36) NOT NULL,
    workflowtask_id character varying(36) NOT NULL,
    file_inode character varying(36) NOT NULL
);


ALTER TABLE public.workflowtask_files OWNER TO dotcms_dev;

--
-- Name: workstream_seq; Type: SEQUENCE; Schema: public; Owner: dotcms_dev
--

CREATE SEQUENCE public.workstream_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.workstream_seq OWNER TO dotcms_dev;

--
-- Name: dist_journal id; Type: DEFAULT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.dist_journal ALTER COLUMN id SET DEFAULT nextval('public.dist_journal_id_seq'::regclass);


--
-- Name: dist_process id; Type: DEFAULT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.dist_process ALTER COLUMN id SET DEFAULT nextval('public.dist_process_id_seq'::regclass);


--
-- Name: dist_reindex_journal id; Type: DEFAULT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.dist_reindex_journal ALTER COLUMN id SET DEFAULT nextval('public.dist_reindex_journal_id_seq'::regclass);


--
-- Name: publishing_queue id; Type: DEFAULT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.publishing_queue ALTER COLUMN id SET DEFAULT nextval('public.publishing_queue_id_seq'::regclass);


--
-- Name: quartz_log id; Type: DEFAULT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.quartz_log ALTER COLUMN id SET DEFAULT nextval('public.quartz_log_id_seq'::regclass);


--
-- Data for Name: address; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.address (addressid, companyid, userid, username, createdate, modifieddate, classname, classpk, description, street1, street2, city, state, zip, country, phone, fax, cell, priority) FROM stdin;
101	dotcms.org	dotcms.org.2557		\N	\N			work	3059 Grand	suite 440	Coconut grove	FL	33133		.305-305-3055			0
14	dotcms.org	dotcms.org.10		\N	\N			work	1234 Maion Street		Miami	FL	33141		123-456-7890			0
181	dotcms.org	dotcms.org.2636		\N	\N			home	asd	asd	asd	asdsad	asd		asd			0
182	dotcms.org	dotcms.org.2637		\N	\N			home	asd	asd	asd	asdsad	asd		asd			0
183	dotcms.org	dotcms.org.2638		\N	\N			home	asd	asd	asd	asdsad	asd		asd			0
184	dotcms.org	dotcms.org.2639		\N	\N			home	asd	asd	asd	asdsad	asd		asd			0
192	dotcms.org	dotcms.org.2645		\N	\N			home	asd	asd	asd	asd	asd		asd			0
193	dotcms.org	dotcms.org.2646		\N	\N			home	asd	asd	asd	asd	asd		asd			0
194	dotcms.org	dotcms.org.2647		\N	\N			home	asd	asd	asd	asd	asd		asd			0
209	dotcms.org	dotcms.org.2662		\N	\N			work	test		test	test	test		test			0
219	dotcms.org	dotcms.org.2673		\N	\N			home	299 S. Main		Andover	MA	01810		978-496-2359			0
220	dotcms.org	dotcms.org.2674		\N	\N			home	299 S. Main		Andover	MA	01810		978-496-2359			0
221	dotcms.org	dotcms.org.2675		\N	\N			Homes	Street1	Street2	city	mq	33133	United States of America	30585815422			0
236	dotcms.org	dotcms.org.2675		\N	\N			Work	asd		asd	as	asas	United States of America	asas			0
296	dotcms.org	dotcms.org.2695		\N	\N			work	3059 Grand Ave	suite 440	Miami	FL	33133	United States of America	305.858.1422			0
314	dotcms.org	dotcms.org.1		\N	\N			dotCMS Office	3059 Grand Ave.	suite 440	Miami	FL	33133	United States of America	305.858.1422			0
324	dotcms.org	dotcms.org.2713		\N	\N			work	3059 Grand Ave.	suite 440	Miami	Florida	33133		305.858.1422			0
332	dotcms.org	dotcms.org.2715		\N	\N			work	asdasd		asdasd	sadsadsad	asdasd		asdasd			0
333	dotcms.org	dotcms.org.2716		\N	\N			work	asdasd		asdasd	sadsadsad	asdasd		asdasd			0
336	dotcms.org	dotcms.org.2719		\N	\N			work	asdasd	asdsad	asdasd	asdsad	asdasd		asdasd	asdsad		0
339	dotcms.org	dotcms.org.2727		\N	\N			home	299 S. Main		Anvoder	MA	01810	United States of America	305.858.1422			0
340	dotcms.org	dotcms.org.2728		\N	\N			home	299 S. Main		Anvoder	MA	01810	United States of America	305.858.1422			0
91	dotcms.org	dotcms.org.2549		\N	\N			work	1 test test		city	IN	zip		phone			0
352	dotcms.org	dotcms.org.2781		\N	\N			Home	Street1	Street2	City	State	55555	Vanuatu	555-55-55	777-77-77		0
355	dotcms.org	dotcms.org.2781		\N	\N			Work	WStreet1	WStreet2	WCity	WState	77777	Vanuatu	777-77-77	999-99-99		0
360	dotcms.org	dotcms.org.2785		\N	\N			home1	add1	2	c2	s2	1234	Angola	4567	789		0
364	dotcms.org	dotcms.org.2800		\N	\N			work	Av. 11		Miami	Florida	33166	USA	123456789			0
365	dotcms.org	dotcms.org.2802		\N	\N			work	2137 Beckenham Drive		Mount Pleasant	SC	29466	US	555-555-5555			0
384	dotcms.org	dotcms.org.2806		\N	\N			work	2137 Beckenham Drive		Mount Pleasant	South Carolina	29466	US	18435551234	18435555678	18435559123	0
\.


--
-- Data for Name: adminconfig; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.adminconfig (configid, companyid, type_, name, config) FROM stdin;
44ead673-8ffa-4146-b4f6-8d63e057a6a8	dotcms.org	USER_CONFIG	USER_CONFIG	<?xml version="1.0" encoding="UTF-8"?>\n<user-config><role-names>Power User</role-names><role-names>User</role-names><registration-email send="false"><body>does not exist</body><subject>[$COMPANY_NAME$] Portal Account</subject></registration-email></user-config>
\.


--
-- Data for Name: analytic_summary; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.analytic_summary (id, summary_period_id, host_id, visits, page_views, unique_visits, new_visits, direct_traffic, referring_sites, search_engines, bounce_rate, avg_time_on_site) FROM stdin;
2	2	a6e85e66-d2c0-4ccf-8d75-24af30780382	0	0	0	0	0	0	0	0	1970-01-01 00:00:00
3	3	a6e85e66-d2c0-4ccf-8d75-24af30780382	0	0	0	0	0	0	0	0	1970-01-01 00:00:00
4	4	a6e85e66-d2c0-4ccf-8d75-24af30780382	0	0	0	0	0	0	0	0	1970-01-01 00:00:00
5	5	a6e85e66-d2c0-4ccf-8d75-24af30780382	0	0	0	0	0	0	0	0	1970-01-01 00:00:00
6	6	a6e85e66-d2c0-4ccf-8d75-24af30780382	0	0	0	0	0	0	0	0	1970-01-01 00:00:00
7	7	a6e85e66-d2c0-4ccf-8d75-24af30780382	0	0	0	0	0	0	0	0	1970-01-01 00:00:00
8	8	a6e85e66-d2c0-4ccf-8d75-24af30780382	0	0	0	0	0	0	0	0	1970-01-01 00:00:00
\.


--
-- Data for Name: analytic_summary_404; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.analytic_summary_404 (id, summary_period_id, host_id, uri, referer_uri) FROM stdin;
\.


--
-- Data for Name: analytic_summary_content; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.analytic_summary_content (id, summary_id, inode, hits, uri, title) FROM stdin;
\.


--
-- Data for Name: analytic_summary_pages; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.analytic_summary_pages (id, summary_id, inode, hits, uri) FROM stdin;
\.


--
-- Data for Name: analytic_summary_period; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.analytic_summary_period (id, full_date, day, week, month, year, dayname, monthname) FROM stdin;
2	2018-03-27 00:00:00	27	5	3	2018	Tuesday	March
3	2018-03-30 00:00:00	30	5	3	2018	Friday	March
4	2018-04-02 00:00:00	2	1	4	2018	Monday	April
5	2018-04-04 00:00:00	4	1	4	2018	Wednesday	April
6	2018-04-05 00:00:00	5	1	4	2018	Thusday	April
7	2018-04-06 00:00:00	6	1	4	2018	Friday	April
8	2018-04-09 00:00:00	9	2	4	2018	Monday	April
\.


--
-- Data for Name: analytic_summary_referer; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.analytic_summary_referer (id, summary_id, hits, uri) FROM stdin;
\.


--
-- Data for Name: analytic_summary_visits; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.analytic_summary_visits (id, summary_period_id, host_id, visit_time, visits) FROM stdin;
\.


--
-- Data for Name: analytic_summary_workstream; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.analytic_summary_workstream (id, inode, asset_type, mod_user_id, host_id, mod_date, action, name) FROM stdin;
2	d6a285b5-2062-4d2a-ab57-ba3966d725b4	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:53.485	Published	Form Success
3	32380acb-a02b-4922-89b8-d680e5843632	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:53.574	Published	Forgot Password
4	776ac303-0943-4598-8e1f-bb97e76df6c0	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:53.664	Published	Let Quest's Financial Advisors help
5	25a2a9b4-6a97-4c72-9713-5d8ea7a14b59	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:53.825	Published	News Details with Angular Comments Component
6	da8e099c-1188-4fa0-bd80-0c5c9cb5fe5d	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:53.925	Published	Our Team
7	d6121323-a504-451f-b06d-d7ef8caafbce	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:54.041	Published	Investor News
8	cee5335a-aec4-4fb5-98d4-3a5fc9b2f046	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:54.123	Published	News
9	951a59da-f1a1-48ba-97cd-0ee8a64dff51	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:54.196	Published	Retirees
10	435c9094-d83d-4a3c-a3c3-324636a7590b	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:54.286	Published	TargetQuest
11	1268a406-4ac5-4de0-b183-8033124dfe56	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:54.394	Published	For Everyone Else
12	7def321f-a56b-4967-8d95-dadbaae49291	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:54.469	Published	Products
13	7b6a67ff-12e8-4faf-b418-d0622a4e653c	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:54.538	Published	Location Detail
14	f16a1a01-51bd-4505-b187-c38a990a657d	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:54.599	Published	Wealth Management Home
15	fc7534d6-0e0f-416a-8239-24b41a3023fa	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:54.654	Published	Reset Password Email Sent
16	c62a9e08-39eb-427f-97a0-f7423ecd7add	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:54.721	Published	Videos
17	8e595cd8-530a-49dc-9aeb-c083662f555b	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:54.777	Published	404 Error
18	2377f408-52c0-4930-a831-a440a5eb4aeb	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:54.856	Published	Create Account
19	0c762640-d365-45ac-a73b-fe152c57418b	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:54.931	Published	Locations
20	4aeca538-e4e4-4e5a-9561-1c0ffa30ea57	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:54.998	Published	News Details
21	fac01161-9620-4722-87be-b47754b2e76a	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:55.071	Published	Photos
22	6074fd0e-8ade-45c8-a0ac-612eda25648c	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:55.215	Published	helloworld
23	895f1899-2ac8-4663-9e78-ac56ed6b91df	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:55.142	Published	helloworld
24	6074fd0e-8ade-45c8-a0ac-612eda25648c	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:55.215	Published	helloworld
25	895f1899-2ac8-4663-9e78-ac56ed6b91df	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:55.142	Published	helloworld
26	af8c198c-9cf5-46b3-94ce-9357d1e9310c	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:55.289	Published	Challenge Question
27	06527885-1fc5-4011-b5e5-ab897b6807e7	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:55.373	Published	location-clickstream.html
28	990a54f6-8ea7-44dd-9b95-1a43a04dfbf3	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:55.462	Published	Products
29	25fa0ad9-e16c-4bef-a150-8eb73c63520a	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:55.538	Published	Bear Mountain
30	b3e476a0-76bd-4373-ada8-79cd10e16ae2	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:55.605	Published	Upload Document
31	02c687c5-95eb-4beb-a7bc-320dd865429d	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:55.695	Published	Home Page
32	e68c1c6e-4eff-46ed-8a06-a42d43ef0e61	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:55.656	Published	Home Page
33	02c687c5-95eb-4beb-a7bc-320dd865429d	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:55.695	Published	Home Page
34	e68c1c6e-4eff-46ed-8a06-a42d43ef0e61	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:55.656	Published	Home Page
35	2bae5bd1-3da3-4c4c-b6c0-13c52f5dcbeb	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:55.757	Published	Contact Us
36	7b6aa234-6ef5-4c42-8388-f1d0c087f3fc	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:55.828	Published	Login
37	d21d7e0b-2b60-40b5-a21f-2b4644bfd7c7	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:55.898	Published	Multi-Containers
38	57575533-3f69-4c8e-82b6-5281331704ec	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:55.97	Published	REST Content Save
39	7db2a52e-b750-462e-9ca0-b7fed7292fe3	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:56.04	Published	For The 1%
40	4ca7d104-7d6e-40b8-8421-ea8ddfcd43b0	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:56.111	Published	Site Search
41	f073d466-135e-42f3-93d6-95f3b46807cc	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:56.164	Published	News RSS
42	9cfac34e-cfc9-400d-b69a-6b15d8019b38	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:56.224	Published	Home
43	315e179b-65e2-4f6b-9891-3e5e53ee164e	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:56.282	Published	Thank You
44	83160aa4-3846-4044-84c6-9f1245059550	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:56.341	Published	Reset Password
45	2eaa2f96-7e28-44b2-986b-63c7b36a2ddc	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:56.424	Published	Event Detail
46	284d47e3-a5d3-42f7-8a6c-3e7cf151308c	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:56.505	Published	Global Investors
47	8e7d8cd4-36c7-4802-bebb-dc2885f90b13	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:56.587	Published	Blogs
48	867d9423-d0e1-4bae-b6a0-b4a6619099cf	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:56.663	Published	Reset Password Confirmation
49	72f763e5-1fe9-4e05-a9a1-d8bf8ec0136a	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:56.73	Published	Remote Widget
50	170d643f-5586-4084-bdca-39cbb7053931	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:56.792	Published	Documents
51	a83f35cb-f830-4c4c-9c1c-e66fcf6c7415	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:56.864	Published	Mobile Apps
52	1eb4d9ea-f309-4e06-8975-3ac60af0dbc1	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:56.922	Published	Blog Detail
53	343c5173-091b-4023-8191-22c785abb8ff	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:56.994	Published	Content Geolocation
54	5ae36bd1-e4dd-4894-809e-d463b5e53fcf	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:57.043	Published	Document Detail
55	dc851757-a856-49bc-afb9-a1c746d706f4	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:57.09	Published	Events
56	5a0486d5-4a85-4f2a-992e-5c58fc58eb76	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:57.154	Published	rss
57	7f485e8c-4bdd-4558-8000-829d93a7544c	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:57.211	Published	Thank You
58	e39fe98b-c50d-427c-936b-f81a6b42928c	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:57.265	Published	Product Detail
59	5c192cb2-6b58-4c10-bdb0-d651460af88c	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:57.324	Published	News Detail
60	3bc6683a-8b7d-41c6-8e7c-9767274b6f69	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:57.485	Published	About Us
61	87f4ef44-2e3f-468a-bea4-69e2cacef610	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:57.415	Published	About Us
62	112a4399-92e2-4a8b-aabb-ede6618a0701	file_asset	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:57.56	Published	First Time Investors
63	4df0f9d8-f80e-4be8-b0ad-5ea5c615772e	template	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:51.519	Published	Intranet - 1 Column
64	14821fe4-97b6-4f57-91f6-81364853e17d	template	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:51.573	Published	Bear Mountain - One Pager
65	a8d42465-8441-4303-974c-2415d9097d0b	template	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:51.692	Published	Quest - Homepage
66	3909313a-ef84-4783-aec0-4ce387caddaf	template	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:51.73	Published	Blank
67	b1183bb9-bd8c-4162-842b-18a141ae23a0	template	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:51.757	Published	Quest - 2 Column (Right Bar)
68	c2d61631-c777-40bf-98a9-107f2d1ca090	template	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:51.778	Published	Intranet - 2 Column
69	d4e6cec6-e1e7-4995-af24-11631162535a	template	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:51.801	Published	Quest - 2 Column (Left Bar)
70	833be7aa-36ab-4e04-9148-82aa654a757c	template	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:51.896	Published	Intranet - 3 Column
71	157325cd-48e4-46ca-bb95-08758975da4c	template	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:51.917	Published	Intranet - Homepage
72	26e95aa3-a474-441a-8ae8-9cfa3aa0acbf	template	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:51.943	Published	Quest - 3 Column
73	20dba2e6-644c-402f-9c6e-e94b0c227c15	template	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:51.993	Published	Quest - 2 Column (w/ Side Nav)
74	8f916a4a-cb43-441a-bbf3-1df76710054c	template	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:52.013	Published	Landing Page
75	e6b938c4-ce24-4d56-9f9c-b109c99d0f2b	template	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:52.049	Published	Quest - 1 Column
76	170c0195-c457-481c-8bd5-6f7761e507e3	template	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:52.075	Saved	anonymous_layout_1520261408317
77	1262dc73-a2ff-4394-aea0-1dc0d6223ba4	container	dotcms.org.1	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:51.425	Published	Default 2 (Page Content)
78	cb04bf31-b913-4b44-9fdd-9ca27a7a2c56	container	dotcms.org.1	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:51.466	Published	Large Column (lg-1)
79	78aa37a8-caf6-47ee-b9f3-ab699a5f72dd	container	dotcms.org.1	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:51.539	Published	Default 4 (Page Content)
80	d5f47f13-ed22-416e-a37c-8ddb2c9b0d76	container	dotcms.org.1	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:51.557	Published	Default 3 (Page Content)
81	0138c668-44fb-4072-b1b4-9af1c6836506	container	dotcms.org.1	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:51.588	Published	Medium Column (md-3)
82	75d898ea-0636-4d39-a9ee-0b6695a5dcd6	container	dotcms.org.1	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:51.606	Published	Small Column (sm-1)
83	1a03bbc3-ac34-45f3-bfbb-efc056a7cc28	container	dotcms.org.1	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:51.625	Published	Medium Column (md-2)
84	50cb25cc-4094-4b2c-8b47-549e535e40f5	container	dotcms.org.1	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:51.644	Published	Banner Carousel 
85	300fa0b6-1776-4822-839b-600e22e87b08	container	dotcms.org.1	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:51.658	Published	Medium Column (md-1)
86	02c951cd-15af-4854-b6b3-839c3088c9d2	container	dotcms.org.1	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:51.676	Published	Promotions (Homepage)
87	c0f2d4fa-ec05-447f-94e2-032a6edea771	container	dotcms.org.1	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:51.709	Published	Blank Container
88	3588d259-1638-48cf-aaa8-5fabfad60306	container	dotcms.org.1	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:51.968	Published	Subnav Menu
89	bd52dba1-f77a-4689-b739-23c322320de3	link	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:53.291	Published	One-Pagers
90	efe32ad8-777b-4aaa-a5d4-9eb73ac4e1ae	link	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:53.322	Published	Blog
91	b684b1b3-ca2f-4b7f-bd37-86a6d688a30b	link	system	a6e85e66-d2c0-4ccf-8d75-24af30780382	2018-03-05 10:10:53.34	Published	Intranet
\.


--
-- Data for Name: api_token_issued; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.api_token_issued (token_id, token_userid, issue_date, expire_date, requested_by_userid, requested_by_ip, revoke_date, allowed_from, issuer, claims, mod_date) FROM stdin;
\.


--
-- Data for Name: broken_link; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.broken_link (id, inode, field, link, title, status_code) FROM stdin;
\.


--
-- Data for Name: calendar_reminder; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.calendar_reminder (user_id, event_id, send_date) FROM stdin;
\.


--
-- Data for Name: campaign; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.campaign (inode, title, from_email, from_name, subject, message, user_id, start_date, completed_date, active, locked, sends_per_hour, sendemail, communicationinode, userfilterinode, sendto, isrecurrent, wassent, expiration_date, parent_campaign) FROM stdin;
\.


--
-- Data for Name: category; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.category (inode, category_name, category_key, sort_order, active, keywords, category_velocity_var_name, mod_date) FROM stdin;
\.


--
-- Data for Name: chain; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.chain (id, key_name, name, success_value, failure_value) FROM stdin;
\.


--
-- Data for Name: chain_link_code; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.chain_link_code (id, class_name, code, last_mod_date, language) FROM stdin;
\.


--
-- Name: chain_link_code_seq; Type: SEQUENCE SET; Schema: public; Owner: dotcms_dev
--

SELECT pg_catalog.setval('public.chain_link_code_seq', 1, false);


--
-- Name: chain_seq; Type: SEQUENCE SET; Schema: public; Owner: dotcms_dev
--

SELECT pg_catalog.setval('public.chain_seq', 1, false);


--
-- Data for Name: chain_state; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.chain_state (id, chain_id, link_code_id, state_order) FROM stdin;
\.


--
-- Data for Name: chain_state_parameter; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.chain_state_parameter (id, chain_state_id, name, value) FROM stdin;
\.


--
-- Name: chain_state_parameter_seq; Type: SEQUENCE SET; Schema: public; Owner: dotcms_dev
--

SELECT pg_catalog.setval('public.chain_state_parameter_seq', 1, false);


--
-- Name: chain_state_seq; Type: SEQUENCE SET; Schema: public; Owner: dotcms_dev
--

SELECT pg_catalog.setval('public.chain_state_seq', 1, false);


--
-- Data for Name: challenge_question; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.challenge_question (cquestionid, cqtext) FROM stdin;
\.


--
-- Data for Name: click; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.click (inode, link, click_count) FROM stdin;
\.


--
-- Data for Name: clickstream; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.clickstream (clickstream_id, cookie_id, user_id, start_date, end_date, referer, remote_address, remote_hostname, user_agent, bot, host_id, last_page_id, first_page_id, operating_system, browser_name, browser_version, mobile_device, number_of_requests) FROM stdin;
\.


--
-- Data for Name: clickstream_404; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.clickstream_404 (clickstream_404_id, referer_uri, query_string, request_uri, user_id, host_id, timestampper) FROM stdin;
\.


--
-- Name: clickstream_404_seq; Type: SEQUENCE SET; Schema: public; Owner: dotcms_dev
--

SELECT pg_catalog.setval('public.clickstream_404_seq', 2, false);


--
-- Data for Name: clickstream_request; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.clickstream_request (clickstream_request_id, clickstream_id, server_name, protocol, server_port, request_uri, request_order, query_string, language_id, timestampper, host_id, associated_identifier) FROM stdin;
\.


--
-- Name: clickstream_request_seq; Type: SEQUENCE SET; Schema: public; Owner: dotcms_dev
--

SELECT pg_catalog.setval('public.clickstream_request_seq', 1, false);


--
-- Name: clickstream_seq; Type: SEQUENCE SET; Schema: public; Owner: dotcms_dev
--

SELECT pg_catalog.setval('public.clickstream_seq', 1, false);


--
-- Data for Name: cluster_server; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.cluster_server (server_id, cluster_id, name, ip_address, host, cache_port, es_transport_tcp_port, es_network_port, es_http_port, key_) FROM stdin;
\.


--
-- Data for Name: cluster_server_action; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.cluster_server_action (server_action_id, originator_id, server_id, failed, response, action_id, completed, entered_date, time_out_seconds) FROM stdin;
\.


--
-- Data for Name: cluster_server_uptime; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.cluster_server_uptime (id, server_id, startup, heartbeat) FROM stdin;
\.


--
-- Data for Name: cms_layout; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.cms_layout (id, layout_name, description, tab_order) FROM stdin;
0c032208-7514-457e-a9e8-26b9e368db64	Publishing	cloud_upload	5
1a87b81c-e7ec-4e5b-9218-b55790353f09	Control Panel	settings_applications	100
34885ddb-3537-4a79-a02c-0550c5087d5c	Dashboard	dashboard	0
56fedb43-dbbf-4ce2-8b77-41fb73bad015	Content Model	event_note	6
57640f2f-3162-4a4b-8418-72ecc898d982	CMS Admin	Permissions & Maintenance	0
b7ab5d3c-5ee0-4195-a17e-8f5579d718dd	Site	account_tree	1
aa91172e-0fa6-482e-9a8b-1c202c7fca0e	Dev Tools	settings_ethernet	7
71b8a1ca-37b6-4b6e-a43b-c7482f28db6c	Content	format_align_left	2
89594b95-1354-4a63-8867-c922880107df	Marketing	filter_center_focus	4
\.


--
-- Data for Name: cms_layouts_portlets; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.cms_layouts_portlets (id, layout_id, portlet_id, portlet_order) FROM stdin;
1ee1ec8b-0906-49e0-82de-d643582ac83b	56fedb43-dbbf-4ce2-8b77-41fb73bad015	content-types-angular	1
2052bf9d-52bb-42ce-a0c7-2bf6ec2b017f	1a87b81c-e7ec-4e5b-9218-b55790353f09	sites	2
286f4147-29d0-44ea-a9a3-910a7a0575b3	1a87b81c-e7ec-4e5b-9218-b55790353f09	configuration	4
47e6816c-0018-4df0-ae5b-0a0fe13860d2	b7ab5d3c-5ee0-4195-a17e-8f5579d718dd	templates	2
4aa6e311-51ea-4443-bddd-43b22ffb47bf	56fedb43-dbbf-4ce2-8b77-41fb73bad015	categories	3
77ce8e9c-3725-437e-96bd-e2a88ea5ff22	1a87b81c-e7ec-4e5b-9218-b55790353f09	roles	3
98abe787-c5fd-470f-9bba-246b7e8e1e82	0c032208-7514-457e-a9e8-26b9e368db64	publishing-queue	1
a402193d-7847-4ead-8a55-87a3a255bce7	1a87b81c-e7ec-4e5b-9218-b55790353f09	users	1
a6f9b699-75ba-4f47-b22a-198584a58e51	56fedb43-dbbf-4ce2-8b77-41fb73bad015	tags	2
b538f3c5-f3a9-436c-9b19-137fe9e30a30	34885ddb-3537-4a79-a02c-0550c5087d5c	embedded-dashboard	1
b9970f27-29ad-4a6d-98b6-9a890485b3ce	56fedb43-dbbf-4ce2-8b77-41fb73bad015	languages	5
bc54d8c0-e72c-4084-a99d-14a021a4e2fb	b7ab5d3c-5ee0-4195-a17e-8f5579d718dd	containers	3
d2458c11-afbd-4b2d-a2e7-43d883926273	56fedb43-dbbf-4ce2-8b77-41fb73bad015	workflow-schemes	4
df993054-1927-43cc-b9a7-3ed03b94924f	0c032208-7514-457e-a9e8-26b9e368db64	time-machine	2
e39c836a-9a33-4836-8e21-2402cd3b431f	b7ab5d3c-5ee0-4195-a17e-8f5579d718dd	site-browser	1
eaff818f-6465-4ac2-9743-4dc2a3603b29	1a87b81c-e7ec-4e5b-9218-b55790353f09	maintenance	5
f6df1827-ed08-464c-9a39-0b93ac602f5d	b7ab5d3c-5ee0-4195-a17e-8f5579d718dd	links	4
fff8553a-5a8b-42b3-b198-0118c4ed12b8	34885ddb-3537-4a79-a02c-0550c5087d5c	workflow	2
9d3ce3b7-bc94-48eb-b653-82af0271f32a	aa91172e-0fa6-482e-9a8b-1c202c7fca0e	site-search	1
1ef0fca5-e187-4560-98a6-502c0da79386	aa91172e-0fa6-482e-9a8b-1c202c7fca0e	dynamic-plugins	2
ca024aec-e668-4bc8-b281-fd17d5194107	aa91172e-0fa6-482e-9a8b-1c202c7fca0e	es-search	3
5af15388-4ccf-464e-a85a-1a3677fcca76	aa91172e-0fa6-482e-9a8b-1c202c7fca0e	query-tool	4
eae7bb80-4fee-468c-a364-3ca37b5f132b	aa91172e-0fa6-482e-9a8b-1c202c7fca0e	dotTools	5
0990808e-55a6-46c4-b2e0-4240682affd1	71b8a1ca-37b6-4b6e-a43b-c7482f28db6c	content	1
5170096d-9ee3-4bc3-8883-2cb82f56e3b8	71b8a1ca-37b6-4b6e-a43b-c7482f28db6c	c_Events	2
6f4726bd-641c-4ce4-8320-27dfc57533dd	71b8a1ca-37b6-4b6e-a43b-c7482f28db6c	calendar	3
4399f874-6e18-45f4-9290-2cc5340fe631	89594b95-1354-4a63-8867-c922880107df	forms	1
9ba4dd5a-dd66-44da-9180-a4454cb99942	89594b95-1354-4a63-8867-c922880107df	c_Personas	2
08528478-f538-4d43-86ae-19629185bfdb	89594b95-1354-4a63-8867-c922880107df	rules	3
125b50d5-7107-4e90-883d-a40634aa46a7	89594b95-1354-4a63-8867-c922880107df	vanity-urls	4
\.


--
-- Data for Name: cms_role; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.cms_role (id, role_name, description, role_key, db_fqn, parent, edit_permissions, edit_users, edit_layouts, locked, system) FROM stdin;
02ae46fa-cb67-4ed8-82d5-f1f9a5e1d744	Publisher / Legal		\N	02ae46fa-cb67-4ed8-82d5-f1f9a5e1d744	02ae46fa-cb67-4ed8-82d5-f1f9a5e1d744	t	t	t	f	f
0d1efa06-a392-44ad-8ace-28c1906043df	Intranet		intranet	0d1efa06-a392-44ad-8ace-28c1906043df	0d1efa06-a392-44ad-8ace-28c1906043df	t	t	f	f	f
2adccac3-a56b-4078-be40-94e343f20712	System	System roles root	System	2adccac3-a56b-4078-be40-94e343f20712	2adccac3-a56b-4078-be40-94e343f20712	f	f	t	f	t
9ac1ff78-71a9-4485-a541-9d1418b17aa4	Users	User Roles root	cms_users	9ac1ff78-71a9-4485-a541-9d1418b17aa4	9ac1ff78-71a9-4485-a541-9d1418b17aa4	f	f	t	f	t
02088e05-5ff5-43c2-a4fa-11a7272cb199	CMS User	CMS User	DOTCMS_BACK_END_USER	2adccac3-a56b-4078-be40-94e343f20712 --> 02088e05-5ff5-43c2-a4fa-11a7272cb199	2adccac3-a56b-4078-be40-94e343f20712	t	t	t	f	t
0f995057-5c35-4ae7-998a-774dda146c63	Anyone who can View Content	Anyone who can View Content	cms_workflow_any_who_can_view	2adccac3-a56b-4078-be40-94e343f20712 --> 0f995057-5c35-4ae7-998a-774dda146c63	2adccac3-a56b-4078-be40-94e343f20712	t	t	f	f	t
15aad986-6d7d-49e3-b643-344158a6e2a1	 		dotcms.org.default	9ac1ff78-71a9-4485-a541-9d1418b17aa4 --> 15aad986-6d7d-49e3-b643-344158a6e2a1	9ac1ff78-71a9-4485-a541-9d1418b17aa4	t	f	t	f	t
1cddb9f9-2443-49f8-a51d-f24f1d7622ac	Report Editor		Report Editor	2adccac3-a56b-4078-be40-94e343f20712 --> 1cddb9f9-2443-49f8-a51d-f24f1d7622ac	2adccac3-a56b-4078-be40-94e343f20712	t	t	t	f	t
276c9923-bd92-43d9-9c27-e86a05eb942d	Guest Guest		dotcms.org.2775	9ac1ff78-71a9-4485-a541-9d1418b17aa4 --> 276c9923-bd92-43d9-9c27-e86a05eb942d	9ac1ff78-71a9-4485-a541-9d1418b17aa4	t	f	t	f	t
29e0af9e-0e60-48ee-b9f7-1453d94d9cb6	Form Editor	Form Editor	Form Editor	2adccac3-a56b-4078-be40-94e343f20712 --> 29e0af9e-0e60-48ee-b9f7-1453d94d9cb6	2adccac3-a56b-4078-be40-94e343f20712	t	t	t	f	t
2bef80c3-e0c7-4d38-8ede-c29930ef29f0	Retailer Intranet		dotcms.org.2783	9ac1ff78-71a9-4485-a541-9d1418b17aa4 --> 2bef80c3-e0c7-4d38-8ede-c29930ef29f0	9ac1ff78-71a9-4485-a541-9d1418b17aa4	t	f	t	f	t
3b2a7733-10ab-4ecb-bc68-880d8ff73c7c	Web Master		dotcms.org.2771	9ac1ff78-71a9-4485-a541-9d1418b17aa4 --> 3b2a7733-10ab-4ecb-bc68-880d8ff73c7c	9ac1ff78-71a9-4485-a541-9d1418b17aa4	t	f	t	f	t
4cbf531f-7792-42b5-921f-5def07d3b361	Limited User		dotcms.org.2765	9ac1ff78-71a9-4485-a541-9d1418b17aa4 --> 4cbf531f-7792-42b5-921f-5def07d3b361	9ac1ff78-71a9-4485-a541-9d1418b17aa4	t	f	t	f	t
4e30795e-176e-4544-b09b-32f40ea1a77d	Blossom Utonium		e6bc8fb9-10fa-40aa-b658-2e817faa3764	9ac1ff78-71a9-4485-a541-9d1418b17aa4 --> 4e30795e-176e-4544-b09b-32f40ea1a77d	9ac1ff78-71a9-4485-a541-9d1418b17aa4	t	f	t	f	t
52181fb6-65c8-4221-8d17-1da8b0e20784	Anyone who can Edit Permissions Content	Anyone who can Edit Permissions Content	cms_workflow_any_who_can_edit_permissions	2adccac3-a56b-4078-be40-94e343f20712 --> 52181fb6-65c8-4221-8d17-1da8b0e20784	2adccac3-a56b-4078-be40-94e343f20712	t	t	f	f	t
617f7300-5c7b-463f-9554-380b918520bc	Anyone who can Edit Content	Anyone who can Edit Content	cms_workflow_any_who_can_edit	2adccac3-a56b-4078-be40-94e343f20712 --> 617f7300-5c7b-463f-9554-380b918520bc	2adccac3-a56b-4078-be40-94e343f20712	t	t	f	f	t
654b0931-1027-41f7-ad4d-173115ed8ec1	CMS Anonymous		CMS Anonymous	2adccac3-a56b-4078-be40-94e343f20712 --> 654b0931-1027-41f7-ad4d-173115ed8ec1	2adccac3-a56b-4078-be40-94e343f20712	t	t	t	f	t
6b1fa42f-8729-4625-80d1-17e4ef691ce7	CMS Owner		CMS Owner	2adccac3-a56b-4078-be40-94e343f20712 --> 6b1fa42f-8729-4625-80d1-17e4ef691ce7	2adccac3-a56b-4078-be40-94e343f20712	t	t	t	f	t
6ea5fcab-7235-4bcd-93ed-7841452b958f	Limited User		dotcms.org.2482	9ac1ff78-71a9-4485-a541-9d1418b17aa4 --> 6ea5fcab-7235-4bcd-93ed-7841452b958f	9ac1ff78-71a9-4485-a541-9d1418b17aa4	t	f	t	f	t
6f9d5449-8f48-4179-a2ad-1983d6217fef	Login As		Login As	2adccac3-a56b-4078-be40-94e343f20712 --> 6f9d5449-8f48-4179-a2ad-1983d6217fef	2adccac3-a56b-4078-be40-94e343f20712	t	t	t	f	t
73ec980e-d74f-4cec-a4d0-e319061e20b9	Admin2 User		dotcms.org.2808	9ac1ff78-71a9-4485-a541-9d1418b17aa4 --> 73ec980e-d74f-4cec-a4d0-e319061e20b9	9ac1ff78-71a9-4485-a541-9d1418b17aa4	t	f	t	f	t
742c9eb3-8651-4df4-b1dc-00c8c64aee4f	LDAP User		LDAP User	2adccac3-a56b-4078-be40-94e343f20712 --> 742c9eb3-8651-4df4-b1dc-00c8c64aee4f	2adccac3-a56b-4078-be40-94e343f20712	t	t	t	f	t
7bc33667-cfc5-4ed7-aae3-56b24e906e6f	Freddy Montes		5fbee5ef-a824-41df-85a6-39b3157db321	9ac1ff78-71a9-4485-a541-9d1418b17aa4 --> 7bc33667-cfc5-4ed7-aae3-56b24e906e6f	9ac1ff78-71a9-4485-a541-9d1418b17aa4	t	f	t	f	t
7f445cf6-1c6d-459e-89f2-20faabe1a001	CMS Power User	CMS Power User	CMS Power User	2adccac3-a56b-4078-be40-94e343f20712 --> 7f445cf6-1c6d-459e-89f2-20faabe1a001	2adccac3-a56b-4078-be40-94e343f20712	t	t	t	f	t
8670b1f4-a8d1-4bcf-9d69-3c7fcfca37f0	Joe News Contributor		dotcms.org.2777	9ac1ff78-71a9-4485-a541-9d1418b17aa4 --> 8670b1f4-a8d1-4bcf-9d69-3c7fcfca37f0	9ac1ff78-71a9-4485-a541-9d1418b17aa4	t	f	t	f	t
88ad9520-70a6-47c3-90cc-91bf0b20ed91	Events User	Events User	Events User	2adccac3-a56b-4078-be40-94e343f20712 --> 88ad9520-70a6-47c3-90cc-91bf0b20ed91	2adccac3-a56b-4078-be40-94e343f20712	t	t	t	f	t
892ab105-f212-407f-8fb4-58ec59310a5e	CMS Administrator		CMS Administrator	2adccac3-a56b-4078-be40-94e343f20712 --> 892ab105-f212-407f-8fb4-58ec59310a5e	2adccac3-a56b-4078-be40-94e343f20712	f	t	t	f	t
8b21a705-5deb-4572-8752-fa0c25c34332	Administrator	Administrator	Administrator	2adccac3-a56b-4078-be40-94e343f20712 --> 8b21a705-5deb-4572-8752-fa0c25c34332	2adccac3-a56b-4078-be40-94e343f20712	t	t	t	f	t
94f53f5d-4ee6-40c8-915c-60ca5a3d257c	Mailing Lists Administrator	Mailing Lists Administrator	Mailing Lists Administrator	2adccac3-a56b-4078-be40-94e343f20712 --> 94f53f5d-4ee6-40c8-915c-60ca5a3d257c	2adccac3-a56b-4078-be40-94e343f20712	t	t	t	f	t
999cd6bf-5cef-4729-8543-696086143884	LoggedIn Site User		DOTCMS_FRONT_END_USER	2adccac3-a56b-4078-be40-94e343f20712 --> 999cd6bf-5cef-4729-8543-696086143884	2adccac3-a56b-4078-be40-94e343f20712	t	t	f	f	t
a21a472c-ad20-4bcd-b395-6f1195100142	Publisher Jane		dotcms.org.2769	9ac1ff78-71a9-4485-a541-9d1418b17aa4 --> a21a472c-ad20-4bcd-b395-6f1195100142	9ac1ff78-71a9-4485-a541-9d1418b17aa4	t	f	t	f	t
a2d88e69-d575-45ec-9b52-0dc3a51468ed	Campaign Manager Admin		Campaign Manager Admin	2adccac3-a56b-4078-be40-94e343f20712 --> a2d88e69-d575-45ec-9b52-0dc3a51468ed	2adccac3-a56b-4078-be40-94e343f20712	t	t	t	f	t
b590cf84-e90d-4f17-a122-1a2b7f243d05	Jason Smith		cfbc9918-3e0e-4596-b89f-573b0dcae965	9ac1ff78-71a9-4485-a541-9d1418b17aa4 --> b590cf84-e90d-4f17-a122-1a2b7f243d05	9ac1ff78-71a9-4485-a541-9d1418b17aa4	t	f	t	f	t
b9236d3a-41d4-4efd-a695-cb0f758cbf86	Guest		\N	2adccac3-a56b-4078-be40-94e343f20712 --> b9236d3a-41d4-4efd-a695-cb0f758cbf86	2adccac3-a56b-4078-be40-94e343f20712	t	t	t	f	f
becdbd18-ba61-4440-b079-f2f9be6a8185	Will Ezell		2ad502fa-6a73-42c1-a3f7-daebb76731d7	9ac1ff78-71a9-4485-a541-9d1418b17aa4 --> becdbd18-ba61-4440-b079-f2f9be6a8185	9ac1ff78-71a9-4485-a541-9d1418b17aa4	t	f	t	f	t
c3eb4526-6d96-48d8-9540-e5fa560cfc0f	Anyone who can Publish Content	Anyone who can Publish Content	cms_workflow_any_who_can_publish	2adccac3-a56b-4078-be40-94e343f20712 --> c3eb4526-6d96-48d8-9540-e5fa560cfc0f	2adccac3-a56b-4078-be40-94e343f20712	t	t	f	f	t
d3684242-00f2-48ab-b9ec-14ed91dc1321	Jason Smith		036fd43a-6d98-46e0-b22e-bae02cb86f0c	9ac1ff78-71a9-4485-a541-9d1418b17aa4 --> d3684242-00f2-48ab-b9ec-14ed91dc1321	9ac1ff78-71a9-4485-a541-9d1418b17aa4	t	f	t	f	t
d3e78673-044a-4e1e-a38a-56f48cc6d5a5	Campaign Manager Viewer		Campaign Manager Viewer	2adccac3-a56b-4078-be40-94e343f20712 --> d3e78673-044a-4e1e-a38a-56f48cc6d5a5	2adccac3-a56b-4078-be40-94e343f20712	t	t	t	f	t
d8beb217-1889-40dd-99ad-fbd3cab7c426	Mailing List Editor		Mailing List Editor	2adccac3-a56b-4078-be40-94e343f20712 --> d8beb217-1889-40dd-99ad-fbd3cab7c426	2adccac3-a56b-4078-be40-94e343f20712	t	t	t	f	t
daf5e2a0-42c7-4799-9d6b-4580bbe6c498	Power User		Power User	2adccac3-a56b-4078-be40-94e343f20712 --> daf5e2a0-42c7-4799-9d6b-4580bbe6c498	2adccac3-a56b-4078-be40-94e343f20712	t	t	t	f	t
dbd027dc-9587-422f-a8be-c7c1ddd08691	Report Administrator		Report Administrator	2adccac3-a56b-4078-be40-94e343f20712 --> dbd027dc-9587-422f-a8be-c7c1ddd08691	2adccac3-a56b-4078-be40-94e343f20712	t	t	t	f	t
e36988eb-f206-4fd3-a06c-6a746d30a772	Reviewer		\N	02ae46fa-cb67-4ed8-82d5-f1f9a5e1d744 --> e36988eb-f206-4fd3-a06c-6a746d30a772	02ae46fa-cb67-4ed8-82d5-f1f9a5e1d744	t	t	t	f	f
e37accbd-6a67-4ff4-adfe-cff423030a0b	Corporate Intranet		dotcms.org.2773	9ac1ff78-71a9-4485-a541-9d1418b17aa4 --> e37accbd-6a67-4ff4-adfe-cff423030a0b	9ac1ff78-71a9-4485-a541-9d1418b17aa4	t	f	t	t	t
e65dc8bc-6a4f-4170-a55c-74fa110285be	Jane News Editor		dotcms.org.2779	9ac1ff78-71a9-4485-a541-9d1418b17aa4 --> e65dc8bc-6a4f-4170-a55c-74fa110285be	9ac1ff78-71a9-4485-a541-9d1418b17aa4	t	f	t	f	t
e7d4e34e-5127-45fc-8123-d48b62d510e3	Admin User		dotcms.org.1	9ac1ff78-71a9-4485-a541-9d1418b17aa4 --> e7d4e34e-5127-45fc-8123-d48b62d510e3	9ac1ff78-71a9-4485-a541-9d1418b17aa4	t	f	t	f	t
e828467a-f128-4d3c-8873-d967631bf130	Events Administrator		Events Administrator	2adccac3-a56b-4078-be40-94e343f20712 --> e828467a-f128-4d3c-8873-d967631bf130	2adccac3-a56b-4078-be40-94e343f20712	t	t	t	f	t
ebe7dc5b-e22d-40b7-a174-00fc12dd19f1	Freddy Montes		1b865d6a-c292-48c3-8705-0cdfc955dd5e	9ac1ff78-71a9-4485-a541-9d1418b17aa4 --> ebe7dc5b-e22d-40b7-a174-00fc12dd19f1	9ac1ff78-71a9-4485-a541-9d1418b17aa4	t	f	t	f	t
edecd377-2321-4803-aa8b-89797dd0d61f	anonymous user anonymous		anonymous	9ac1ff78-71a9-4485-a541-9d1418b17aa4 --> edecd377-2321-4803-aa8b-89797dd0d61f	9ac1ff78-71a9-4485-a541-9d1418b17aa4	t	f	t	f	t
efaae597-c6d2-4636-9061-8c47a454ea30	User Manager Editor		User Manager Editor	2adccac3-a56b-4078-be40-94e343f20712 --> efaae597-c6d2-4636-9061-8c47a454ea30	2adccac3-a56b-4078-be40-94e343f20712	t	t	t	f	t
f0fd2519-e420-4579-bcc3-d364fb7d6249	Will Ezell		09dddbf5-1303-4b5f-9bf2-c18d6e6becf6	9ac1ff78-71a9-4485-a541-9d1418b17aa4 --> f0fd2519-e420-4579-bcc3-d364fb7d6249	9ac1ff78-71a9-4485-a541-9d1418b17aa4	t	f	t	f	t
f10eab25-ab4b-444f-b1b5-15a1a5948024	User Manager Administrator		User Manager Administrator	2adccac3-a56b-4078-be40-94e343f20712 --> f10eab25-ab4b-444f-b1b5-15a1a5948024	2adccac3-a56b-4078-be40-94e343f20712	t	t	t	f	t
f3fed6bd-cf80-465f-8e61-d9bfa480c23a	Campaign Manager Editor		Campaign Manager Editor	2adccac3-a56b-4078-be40-94e343f20712 --> f3fed6bd-cf80-465f-8e61-d9bfa480c23a	2adccac3-a56b-4078-be40-94e343f20712	t	t	t	f	t
f4837c7f-e753-47ff-8626-54383974a5e6	User		User	2adccac3-a56b-4078-be40-94e343f20712 --> f4837c7f-e753-47ff-8626-54383974a5e6	2adccac3-a56b-4078-be40-94e343f20712	t	t	t	f	t
f8ac2f2c-d4db-451d-8c5c-165d8276b266	Report Viewer		Report Viewer	2adccac3-a56b-4078-be40-94e343f20712 --> f8ac2f2c-d4db-451d-8c5c-165d8276b266	2adccac3-a56b-4078-be40-94e343f20712	t	t	t	f	t
f923366a-b1a3-41d5-9d6a-f10c1f58c511	Ecomm User	Ecomm User	Ecomm User	2adccac3-a56b-4078-be40-94e343f20712 --> f923366a-b1a3-41d5-9d6a-f10c1f58c511	2adccac3-a56b-4078-be40-94e343f20712	t	t	t	f	t
ff4d1504-a077-4874-b89b-9844d10d5b6d	Scripting User		Scripting Developer	2adccac3-a56b-4078-be40-94e343f20712 --> ff4d1504-a077-4874-b89b-9844d10d5b6d	2adccac3-a56b-4078-be40-94e343f20712	f	t	f	f	f
db0d2bca-5da5-4c18-b5d7-87f02ba58eb6	Contributor		\N	02ae46fa-cb67-4ed8-82d5-f1f9a5e1d744 --> e36988eb-f206-4fd3-a06c-6a746d30a772 --> db0d2bca-5da5-4c18-b5d7-87f02ba58eb6	e36988eb-f206-4fd3-a06c-6a746d30a772	t	t	t	f	f
\.


--
-- Data for Name: cms_roles_ir; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.cms_roles_ir (name, role_key, local_role_id, remote_role_id, local_role_fqn, remote_role_fqn, endpoint_id) FROM stdin;
\.


--
-- Data for Name: communication; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.communication (inode, title, trackback_link_inode, communication_type, from_name, from_email, email_subject, html_page_inode, text_message, mod_date, modified_by, ext_comm_id) FROM stdin;
\.


--
-- Data for Name: company; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.company (companyid, key_, portalurl, homeurl, mx, name, shortname, type_, size_, street, city, state, zip, phone, fax, emailaddress, authtype, autologin, strangers) FROM stdin;
liferay.com	\N	localhost	localhost	liferay.com	Liferay, LLC	Liferay	#C336E5		#54428E	Diamond Bar	CA	91789	\N	\N	test@liferay.com	emailAddress	t	t
dotcms.org	rO0ABXNyAB9qYXZheC5jcnlwdG8uc3BlYy5TZWNyZXRLZXlTcGVjW0cLZuIwYU0CAAJMAAlhbGdvcml0aG10ABJMamF2YS9sYW5nL1N0cmluZztbAANrZXl0AAJbQnhwdAADQUVTdXIAAltCrPMX+AYIVOACAAB4cAAAACAF1Wr9WjmZYf4GeC582IR0Ua9nzIxPJc5sy5kE4FWwew==	localhost	/html/images/backgrounds/bg-11.jpg	dotcms.com	dotcms.org	dotcms.org	#c336e5	#28283e	#6f5fa3	Miami	FL	33133	3058581422		support@dotcms.com	emailAddress	t	f
\.


--
-- Data for Name: container_structures; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.container_structures (id, container_id, container_inode, structure_id, code) FROM stdin;
\.


--
-- Data for Name: container_version_info; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.container_version_info (identifier, working_inode, live_inode, deleted, locked_by, locked_on, version_ts) FROM stdin;
\.


--
-- Data for Name: content_rating; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.content_rating (id, rating, user_id, session_id, identifier, rating_date, user_ip, long_live_cookie_id) FROM stdin;
\.


--
-- Name: content_rating_sequence; Type: SEQUENCE SET; Schema: public; Owner: dotcms_dev
--

SELECT pg_catalog.setval('public.content_rating_sequence', 2, false);


--
-- Data for Name: contentlet; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.contentlet (inode, show_on_menu, title, mod_date, mod_user, sort_order, friendly_name, structure_inode, last_review, next_review, review_interval, disabled_wysiwyg, identifier, language_id, date1, date2, date3, date4, date5, date6, date7, date8, date9, date10, date11, date12, date13, date14, date15, date16, date17, date18, date19, date20, date21, date22, date23, date24, date25, text1, text2, text3, text4, text5, text6, text7, text8, text9, text10, text11, text12, text13, text14, text15, text16, text17, text18, text19, text20, text21, text22, text23, text24, text25, text_area1, text_area2, text_area3, text_area4, text_area5, text_area6, text_area7, text_area8, text_area9, text_area10, text_area11, text_area12, text_area13, text_area14, text_area15, text_area16, text_area17, text_area18, text_area19, text_area20, text_area21, text_area22, text_area23, text_area24, text_area25, integer1, integer2, integer3, integer4, integer5, integer6, integer7, integer8, integer9, integer10, integer11, integer12, integer13, integer14, integer15, integer16, integer17, integer18, integer19, integer20, integer21, integer22, integer23, integer24, integer25, float1, float2, float3, float4, float5, float6, float7, float8, float9, float10, float11, float12, float13, float14, float15, float16, float17, float18, float19, float20, float21, float22, float23, float24, float25, bool1, bool2, bool3, bool4, bool5, bool6, bool7, bool8, bool9, bool10, bool11, bool12, bool13, bool14, bool15, bool16, bool17, bool18, bool19, bool20, bool21, bool22, bool23, bool24, bool25) FROM stdin;
0c3418eb-4c27-4d71-937d-bf231399312a	f	demo.dotcms.com	2020-02-04 10:44:16.732	dotcms.org.1	0	demo.dotcms.com	855a2d72-f2f3-4169-8b04-ac5157c4380c	2020-02-04 10:44:16.724	\N	\N		48190c8c-42c4-46af-8d1a-0cd5db894797	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	demo.dotcms.com	ra-4e02119211875e7b	\N	SYSTEM_HOST	AIzaSyDXvD7JA5Q8S5VgfviI8nDinAq9x5Utmu0	UA-9877660-3	https://ematest.dotcms.com:8443	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	test.dotcms.com\ntest2.dotcms.com\nlocalhost\n127.0.0.1	dotCMS starter site was designed to demonstrate what you can do with dotCMS.	CMS, Web Content Management, Open Source, Java, J2EE, DXP, NoCode, OSGI, Apache Velocity, Elasticsearch, RESTful Services, REST API, Workflows, Personalization, Multilingual, I18N, L10N, Internationalization, Localization, Docker CMS, Containerized CMS	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	t	f	f	f	f	f	f	f	f	f	f	f	f	f	f	f	f	f	f	f	f	f	f	f	f
dbdec5e2-c02b-4cfb-83a9-4a4c4f3b2eb0	f	System Host	2009-11-17 12:55:33	system	0	System Host	855a2d72-f2f3-4169-8b04-ac5157c4380c	\N	\N	\N	\N	SYSTEM_HOST	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	System Host				\N	\N		\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N		\N	\N		\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	f	t	f	f	f	f	f	f	f	f	f	f	f	f	f	f	f	f	f	f	f	f	f	f	f
\.


--
-- Data for Name: contentlet_version_info; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.contentlet_version_info (identifier, lang, working_inode, live_inode, deleted, locked_by, locked_on, version_ts) FROM stdin;
48190c8c-42c4-46af-8d1a-0cd5db894797	1	0c3418eb-4c27-4d71-937d-bf231399312a	0c3418eb-4c27-4d71-937d-bf231399312a	f	\N	2020-02-04 10:44:16.822	2020-02-04 10:44:16.795
SYSTEM_HOST	1	dbdec5e2-c02b-4cfb-83a9-4a4c4f3b2eb0	dbdec5e2-c02b-4cfb-83a9-4a4c4f3b2eb0	f	\N	2012-06-07 05:46:26	2019-05-17 16:44:10.494
\.


--
-- Data for Name: counter; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.counter (name, currentid) FROM stdin;
com.liferay.portal.model.Group	34
com.liferay.portal.model.PasswordTracker	2
com.liferay.portal.model.Role	138
com.liferay.portal.model.User.liferay.com	10
com.liferay.portlet.imagegallery.model.IGFolder	20
com.liferay.portlet.imagegallery.model.IGImage.liferay.com	42
com.liferay.portlet.shopping.model.ShoppingCategory	20
com.liferay.portlet.shopping.model.ShoppingItem	40
com.liferay.portlet.wiki.model.WikiNode	10
com.liferay.portlet.polls.model.PollsQuestion.anonymous	21
com.liferay.portlet.polls.model.PollsQuestion	13
com.liferay.portal.model.Address	555
com.liferay.portlet.admin.model.AdminConfig	44
com.liferay.portal.model.User.dotcms.org	2927
\.


--
-- Data for Name: dashboard_user_preferences; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.dashboard_user_preferences (id, summary_404_id, user_id, ignored, mod_date) FROM stdin;
\.


--
-- Name: dashboard_usrpref_seq; Type: SEQUENCE SET; Schema: public; Owner: dotcms_dev
--

SELECT pg_catalog.setval('public.dashboard_usrpref_seq', 2, false);


--
-- Data for Name: db_version; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.db_version (db_version, date_update) FROM stdin;
0	2020-03-26 00:00:00-04
760	2020-03-26 00:00:00-04
765	2020-03-26 00:00:00-04
766	2020-03-26 00:00:00-04
767	2020-03-26 00:00:00-04
768	2020-03-26 00:00:00-04
769	2020-03-26 00:00:00-04
775	2020-03-26 00:00:00-04
780	2020-03-26 00:00:00-04
782	2020-03-26 00:00:00-04
785	2020-03-26 00:00:00-04
790	2020-03-26 00:00:00-04
795	2020-03-26 00:00:00-04
800	2020-03-26 00:00:00-04
805	2020-03-26 00:00:00-04
810	2020-03-26 00:00:00-04
815	2020-03-26 00:00:00-04
820	2020-03-26 00:00:00-04
825	2020-03-26 00:00:00-04
835	2020-03-26 00:00:00-04
840	2020-03-26 00:00:00-04
845	2020-03-26 00:00:00-04
850	2020-03-26 00:00:00-04
855	2020-03-26 00:00:00-04
860	2020-03-26 00:00:00-04
865	2020-03-26 00:00:00-04
900	2020-03-26 00:00:00-04
905	2020-03-26 00:00:00-04
910	2020-03-26 00:00:00-04
920	2020-03-26 00:00:00-04
922	2020-03-26 00:00:00-04
925	2020-03-26 00:00:00-04
930	2020-03-26 00:00:00-04
935	2020-03-26 00:00:00-04
940	2020-03-26 00:00:00-04
945	2020-03-26 00:00:00-04
950	2020-03-26 00:00:00-04
1000	2020-03-26 00:00:00-04
1005	2020-03-26 00:00:00-04
1015	2020-03-26 00:00:00-04
1016	2020-03-26 00:00:00-04
1020	2020-03-26 00:00:00-04
1030	2020-03-26 00:00:00-04
1035	2020-03-26 00:00:00-04
1045	2020-03-26 00:00:00-04
1050	2020-03-26 00:00:00-04
1055	2020-03-26 00:00:00-04
1060	2020-03-26 00:00:00-04
1065	2020-03-26 00:00:00-04
1070	2020-03-26 00:00:00-04
1080	2020-03-26 00:00:00-04
1085	2020-03-26 00:00:00-04
1090	2020-03-26 00:00:00-04
1095	2020-03-26 00:00:00-04
1096	2020-03-26 00:00:00-04
3000	2020-03-26 00:00:00-04
3005	2020-03-26 00:00:00-04
3010	2020-03-26 00:00:00-04
3015	2020-03-26 00:00:00-04
3020	2020-03-26 00:00:00-04
3025	2020-03-26 00:00:00-04
3030	2020-03-26 00:00:00-04
3035	2020-03-26 00:00:00-04
3040	2020-03-26 00:00:00-04
3042	2020-03-26 00:00:00-04
3045	2020-03-26 00:00:00-04
3050	2020-03-26 00:00:00-04
3055	2020-03-26 00:00:00-04
3060	2020-03-26 00:00:00-04
3065	2020-03-26 00:00:00-04
3100	2020-03-26 00:00:00-04
3105	2020-03-26 00:00:00-04
3120	2020-03-26 00:00:00-04
3130	2020-03-26 00:00:00-04
3135	2020-03-26 00:00:00-04
3140	2020-03-26 00:00:00-04
3150	2020-03-26 00:00:00-04
3160	2020-03-26 00:00:00-04
3165	2020-03-26 00:00:00-04
3500	2020-03-26 00:00:00-04
3505	2020-03-26 00:00:00-04
3510	2020-03-26 00:00:00-04
3515	2020-03-26 00:00:00-04
3520	2020-03-26 00:00:00-04
3525	2020-03-26 00:00:00-04
3530	2020-03-26 00:00:00-04
3535	2020-03-26 00:00:00-04
3540	2020-03-26 00:00:00-04
3545	2020-03-26 00:00:00-04
3550	2020-03-26 00:00:00-04
3555	2020-03-26 00:00:00-04
3560	2020-03-26 00:00:00-04
3565	2020-03-26 00:00:00-04
3600	2020-03-26 00:00:00-04
3605	2020-03-26 00:00:00-04
3700	2020-03-26 00:00:00-04
3705	2020-03-26 00:00:00-04
3710	2020-03-26 00:00:00-04
3715	2020-03-26 00:00:00-04
3720	2020-03-26 00:00:00-04
3725	2020-03-26 00:00:00-04
3735	2020-03-26 00:00:00-04
3740	2020-03-26 00:00:00-04
3745	2020-03-26 00:00:00-04
3800	2020-03-26 00:00:00-04
4100	2020-03-26 00:00:00-04
4105	2020-03-26 00:00:00-04
4110	2020-03-26 00:00:00-04
4115	2020-03-26 00:00:00-04
4120	2020-03-26 00:00:00-04
4200	2020-03-26 00:00:00-04
4205	2020-03-26 00:00:00-04
4210	2020-03-26 00:00:00-04
4215	2020-03-26 00:00:00-04
4220	2020-03-26 00:00:00-04
4230	2020-03-26 00:00:00-04
4235	2020-03-26 00:00:00-04
4300	2020-03-26 00:00:00-04
4305	2020-03-26 00:00:00-04
4310	2020-03-26 00:00:00-04
4315	2020-03-26 00:00:00-04
4320	2020-03-26 00:00:00-04
4330	2020-03-26 00:00:00-04
4335	2020-03-26 00:00:00-04
4340	2020-03-26 00:00:00-04
4345	2020-03-26 00:00:00-04
4350	2020-03-26 00:00:00-04
4355	2020-03-26 00:00:00-04
4360	2020-03-26 00:00:00-04
4365	2020-03-26 00:00:00-04
4370	2020-03-26 00:00:00-04
4375	2020-03-26 00:00:00-04
4380	2020-03-26 00:00:00-04
4385	2020-03-26 00:00:00-04
4390	2020-03-26 00:00:00-04
5030	2020-03-26 00:00:00-04
5035	2020-03-26 00:00:00-04
5040	2020-03-26 00:00:00-04
5050	2020-03-26 00:00:00-04
5060	2020-03-26 00:00:00-04
5070	2020-03-26 00:00:00-04
5080	2020-03-26 00:00:00-04
5150	2020-03-26 00:00:00-04
5160	2020-03-26 00:00:00-04
5165	2020-03-26 00:00:00-04
5170	2020-03-26 00:00:00-04
5175	2020-03-26 00:00:00-04
5180	2020-03-26 00:00:00-04
5190	2020-03-26 00:00:00-04
5195	2020-03-26 00:00:00-04
5200	2020-03-26 00:00:00-04
5210	2020-03-26 00:00:00-04
5215	2020-03-26 00:00:00-04
5220	2020-03-26 00:00:00-04
\.


--
-- Data for Name: dist_journal; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.dist_journal (id, object_to_index, serverid, journal_type, time_entered) FROM stdin;
\.


--
-- Name: dist_journal_id_seq; Type: SEQUENCE SET; Schema: public; Owner: dotcms_dev
--

SELECT pg_catalog.setval('public.dist_journal_id_seq', 2, false);


--
-- Data for Name: dist_process; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.dist_process (id, object_to_index, serverid, journal_type, time_entered) FROM stdin;
\.


--
-- Name: dist_process_id_seq; Type: SEQUENCE SET; Schema: public; Owner: dotcms_dev
--

SELECT pg_catalog.setval('public.dist_process_id_seq', 1, false);


--
-- Data for Name: dist_reindex_journal; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.dist_reindex_journal (id, inode_to_index, ident_to_index, serverid, priority, time_entered, index_val, dist_action) FROM stdin;
\.


--
-- Name: dist_reindex_journal_id_seq; Type: SEQUENCE SET; Schema: public; Owner: dotcms_dev
--

SELECT pg_catalog.setval('public.dist_reindex_journal_id_seq', 5942, true);


--
-- Data for Name: dot_cluster; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.dot_cluster (cluster_id) FROM stdin;
15fbaf73-1c82-4ad5-ad2b-ac2d13e81672
\.


--
-- Data for Name: dot_containers; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.dot_containers (inode, code, pre_loop, post_loop, show_on_menu, title, mod_date, mod_user, sort_order, friendly_name, max_contentlets, use_div, staticify, sort_contentlets_by, lucene_query, notes, identifier) FROM stdin;
\.


--
-- Data for Name: dot_rule; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.dot_rule (id, name, fire_on, short_circuit, parent_id, folder, priority, enabled, mod_date) FROM stdin;
f371e13f-a2ed-4b74-afea-42e486eda82c	Persona	EVERY_PAGE	f	c56e5030-fc88-480c-9b2e-4582fd762437	SYSTEM_FOLDER	1	t	2020-03-26 00:35:27.97
534584eb-5164-455e-a118-222a7a8a9f50	Set Persona	EVERY_PAGE	f	740235e1-407b-4e7c-84bb-e9f5948079e5	SYSTEM_FOLDER	1	t	2020-03-26 00:35:27.998
2622534d-5805-47b3-9334-0b5bbb56731f	Set Persona	EVERY_PAGE	f	388f8690-a64f-4982-9c81-cf6f3ec5ea30	SYSTEM_FOLDER	1	t	2020-03-26 00:35:28.008
e3bf0b13-5886-4c27-a2da-37f739d2852b	Set Persona	EVERY_PAGE	f	53733761-4836-4dca-8787-81660feeee58	SYSTEM_FOLDER	1	t	2020-03-26 00:35:28.018
21c77092-d638-41cd-b1dd-3bc5e4fffe60	Set Persona	EVERY_PAGE	f	77f953d1-529e-435c-8195-630efbb6bf58	SYSTEM_FOLDER	1	t	2020-03-26 00:35:28.028
a29ba0ed-97a8-479c-abec-fc7ec729c326	Chrome Rule 	EVERY_PAGE	f	44a076ad-affa-49d4-97b3-6caa3824e7e8	SYSTEM_FOLDER	1	t	2020-03-26 00:35:28.05
fc0f85a6-6853-4e51-ab5d-4122b3207202	test rule	EVERY_PAGE	f	44a076ad-affa-49d4-97b3-6caa3824e7e8	SYSTEM_FOLDER	2	f	2020-03-26 00:35:28.08
44da6828-bf51-42ab-9982-bd80e023d33a	Set Persona - Eco	EVERY_PAGE	f	bec7b960-a8bf-4f14-a22b-0d94caf217f0	SYSTEM_FOLDER	2	t	2020-03-26 00:35:28.11
\.


--
-- Data for Name: field; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.field (inode, structure_inode, field_name, field_type, field_relation_type, field_contentlet, required, indexed, listed, velocity_var_name, sort_order, field_values, regex_check, hint, default_value, fixed, read_only, searchable, unique_, mod_date) FROM stdin;
05b6edc6-6443-4dc7-a884-f029b12e5a0d	f4d7c1b8-2c88-4071-abf1-a5328977b07d	Key	com.dotcms.contenttype.model.field.TextField	\N	text1	t	t	t	key	1	\N	\N	\N	\N	t	f	t	t	2020-03-26 00:35:03
c7829c13-cf47-4a20-9331-85fb314cef8e	f4d7c1b8-2c88-4071-abf1-a5328977b07d	Value	com.dotcms.contenttype.model.field.TextAreaField	\N	text_area1	t	t	t	value	2	\N	\N	\N	\N	t	f	t	f	2020-03-26 00:35:04
ba99667c-87be-44cd-82b6-4aa7bb157ac7	c541abb1-69b3-4bc5-8430-5e09e5239cc8	Redirect Url	com.dotcms.contenttype.model.field.CustomField	\N	text8	f	t	f	redirecturl	27	$velutil.mergeTemplate('/static/htmlpage_assets/redirect_custom_field.vtl')	\N	\N	\N	t	f	t	f	2020-03-26 00:35:06
4e64a309-8c5e-48cf-b4a9-e724a5e09575	8e850645-bb92-4fda-a765-e67063a59be0	Title	com.dotcms.contenttype.model.field.TextField	\N	text1	t	t	t	title	1	\N	\N	\N	\N	t	f	t	f	2020-03-26 00:35:04
3b7f25bb-c5be-48bb-b00b-5b1b754e550c	8e850645-bb92-4fda-a765-e67063a59be0	Site	com.dotcms.contenttype.model.field.CustomField	\N	text2	t	t	f	site	2	$velutil.mergeTemplate('/static/content/site_selector_field_render.vtl')	\N	\N	\N	t	f	f	f	2020-03-26 00:35:04
de4fea7f-4d8f-48eb-8a63-20772dced99a	8e850645-bb92-4fda-a765-e67063a59be0	Uri	com.dotcms.contenttype.model.field.TextField	\N	text3	t	t	t	uri	3	\N	\N	\N	\N	t	f	t	f	2020-03-26 00:35:04
7e438b93-b631-4812-9c9c-331b03e6b1cd	8e850645-bb92-4fda-a765-e67063a59be0	Action	com.dotcms.contenttype.model.field.SelectField	\N	integer1	t	t	t	action	4	200 - Forward|200\r\n301 - Permanent Redirect|301\r\n302 - Temporary Redirect|302	\N	\N	\N	t	f	t	f	2020-03-26 00:35:04
49f3803a-b2b0-4e03-bb2e-d1bb2a1c135e	8e850645-bb92-4fda-a765-e67063a59be0	Forward To	com.dotcms.contenttype.model.field.CustomField	\N	text4	t	t	t	forwardTo	5	$velutil.mergeTemplate('/static/content/file_browser_field_render.vtl')	\N	\N	\N	t	f	f	f	2020-03-26 00:35:04
9ae3e58a-75c9-4e4a-90f3-6f0d5f32a6f0	8e850645-bb92-4fda-a765-e67063a59be0	Order	com.dotcms.contenttype.model.field.TextField	\N	integer2	t	t	f	order	6	\N	\N	\N	0	t	f	t	f	2020-03-26 00:35:04
31519868-f318-4447-88e7-0ffc2fe4b2cd	4d21b6d8-1711-4ae6-9419-89e2b1ae5a06	Form ID	com.dotcms.contenttype.model.field.TextField	\N	text1	t	t	t	formId	1	\N	\N	\N	\N	t	f	t	f	2020-03-26 00:35:04
8859f1ed-84ad-4105-acda-5d5d29553d9b	4d21b6d8-1711-4ae6-9419-89e2b1ae5a06	Widget Title	com.dotcms.contenttype.model.field.TextField	\N	text3	t	t	t	widgetTitle	1	\N	\N	\N	\N	t	f	t	f	2020-03-26 00:35:04
d12a2a4f-45f1-4194-95e3-338865e7afde	4d21b6d8-1711-4ae6-9419-89e2b1ae5a06	Widget Usage	com.dotcms.contenttype.model.field.ConstantField	\N	system_field	f	t	f	widgetUsage	2	\N	\N	\N	\N	t	t	t	f	2020-03-26 00:35:04
e5666638-e7f4-4b3a-b6d3-22f8d13188e8	4d21b6d8-1711-4ae6-9419-89e2b1ae5a06	Widget Code	com.dotcms.contenttype.model.field.ConstantField	\N	system_field	f	f	f	widgetCode	3	$velutil.mergeTemplate('/static/content/content_form.vtl')	\N	\N	\N	t	f	f	f	2020-03-26 00:35:04
6b33d6be-d197-4f9e-8fc3-d20d36e08c75	4d21b6d8-1711-4ae6-9419-89e2b1ae5a06	Widget Pre-Execute	com.dotcms.contenttype.model.field.ConstantField	\N	system_field	f	t	f	widgetPreexecute	4	\N	\N	\N	\N	t	t	t	f	2020-03-26 00:35:04
e633ab20-0aa1-4ed1-b052-82a711af61df	c541abb1-69b3-4bc5-8430-5e09e5239cc8	Cache TTL	com.dotcms.contenttype.model.field.CustomField	\N	text4	t	t	f	cachettl	28	$velutil.mergeTemplate('/static/htmlpage_assets/cachettl_custom_field.vtl')	^[0-9]+$	\N	\N	t	f	t	f	2020-03-26 00:35:07
b0d65eee-b050-4fa2-bcf6-4016dc4e20af	c541abb1-69b3-4bc5-8430-5e09e5239cc8	HTTPS Required	com.dotcms.contenttype.model.field.CheckboxField	\N	text9	f	t	f	httpsreq	29	|true	\N	\N	false	t	f	f	f	2020-03-26 00:35:07
ed1ca7ce-08fb-4a4f-814c-3add0e750625	c6e3a3c6-a0c6-494b-9ae8-bde7322bc68e	fields-0	com.dotcms.contenttype.model.field.RowField	\N	system_field	f	f	f	fields0	1	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:04
615957f5-6a44-4952-b321-915c35bbfaeb	c6e3a3c6-a0c6-494b-9ae8-bde7322bc68e	fields-1	com.dotcms.contenttype.model.field.ColumnField	\N	system_field	f	f	f	fields1	2	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:04
3ff698f0-6edf-4cf1-80ee-34fd3e9e3b70	c6e3a3c6-a0c6-494b-9ae8-bde7322bc68e	Name	com.dotcms.contenttype.model.field.TextField	\N	text1	t	t	t	name	3	\N	\N	\N	\N	f	f	t	f	2020-03-26 00:35:04
fa7ac3d7-d442-4477-8662-a88885352728	c6e3a3c6-a0c6-494b-9ae8-bde7322bc68e	Physical Width	com.dotcms.contenttype.model.field.TextField	\N	integer2	f	f	f	physicalWidth	4	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:04
12af029c-217a-45ee-a683-baab61ee7ddf	c6e3a3c6-a0c6-494b-9ae8-bde7322bc68e	Physical Height	com.dotcms.contenttype.model.field.TextField	\N	integer3	f	f	f	physicalHeight	5	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:04
7d10f7dc-cf0f-405d-ae4b-1d46942b4a8f	c6e3a3c6-a0c6-494b-9ae8-bde7322bc68e	CSS Width	com.dotcms.contenttype.model.field.TextField	\N	text2	t	t	t	cssWidth	6	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:04
848ec05e-2c89-483f-98de-adca6f9a77fe	c6e3a3c6-a0c6-494b-9ae8-bde7322bc68e	CSS Height	com.dotcms.contenttype.model.field.TextField	\N	text3	t	t	t	cssHeight	7	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:05
e59fa37c-29dd-43ab-bbe2-b9bb92036c59	c6e3a3c6-a0c6-494b-9ae8-bde7322bc68e	Pixel Ratio	com.dotcms.contenttype.model.field.TextField	\N	float1	f	t	t	pixelRatio	8	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:05
000ef75f-59e2-4c89-9cec-247e371ecd77	c6e3a3c6-a0c6-494b-9ae8-bde7322bc68e	Physical ppi	com.dotcms.contenttype.model.field.TextField	\N	text4	f	f	f	physicalPpi	9	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:05
48633376-bd98-4f3e-98bb-7616f057a735	c6e3a3c6-a0c6-494b-9ae8-bde7322bc68e	CSS ppi	com.dotcms.contenttype.model.field.TextField	\N	integer1	f	f	f	cssPpi	10	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:05
606ac3af-63e5-4bd4-bfa1-c4c672bb8eb8	c938b15f-bcb6-49ef-8651-14d455a97045	Site/Folder	com.dotcms.contenttype.model.field.HostFolderField	\N	system_field	t	t	f	hostFolder	1	\N	\N	\N	\N	t	f	t	f	2020-03-26 00:35:05
0ea2bd92-4b2d-48a2-a394-77fd560b1fce	c938b15f-bcb6-49ef-8651-14d455a97045	Name	com.dotcms.contenttype.model.field.TextField	\N	text1	t	t	t	name	2	\N	\N	\N	\N	t	f	t	f	2020-03-26 00:35:05
6b25d960-034d-4030-b785-89cc01baaa3d	c938b15f-bcb6-49ef-8651-14d455a97045	Key Tag	com.dotcms.contenttype.model.field.CustomField	\N	text2	t	t	t	keyTag	3	$velutil.mergeTemplate('/static/personas/keytag_custom_field.vtl')	[a-zA-Z0-9]+	\N	\N	t	f	t	f	2020-03-26 00:35:05
07cfbc2c-47de-4c78-a411-176fe8bb24a5	c938b15f-bcb6-49ef-8651-14d455a97045	Photo	com.dotcms.contenttype.model.field.BinaryField	\N	system_field	f	f	f	photo	4	\N	\N	\N	\N	t	f	f	f	2020-03-26 00:35:05
2dab7223-ebb5-411b-922f-611a30bc2a2b	c938b15f-bcb6-49ef-8651-14d455a97045	Other Tags	com.dotcms.contenttype.model.field.TagField	\N	system_field	f	t	f	tags	5	\N	\N	\N	\N	t	f	t	f	2020-03-26 00:35:05
65e4e742-d87a-47ff-84ef-fde44e889e27	c938b15f-bcb6-49ef-8651-14d455a97045	Description	com.dotcms.contenttype.model.field.TextAreaField	\N	text_area2	f	t	f	description	6	\N	\N	\N	\N	t	f	t	f	2020-03-26 00:35:05
fdb123f4-52aa-4ac0-b631-cc0308ca51ff	c541abb1-69b3-4bc5-8430-5e09e5239cc8	fields-0	com.dotcms.contenttype.model.field.RowField	\N	system_field	f	f	f	fields0	0	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:06
fb2639d0-c6ef-4e66-8cbd-994a1084614e	c541abb1-69b3-4bc5-8430-5e09e5239cc8	fields-1	com.dotcms.contenttype.model.field.ColumnField	\N	system_field	f	f	f	fields1	1	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:06
23b5f1be-935e-442e-be48-1cf2d1c96d71	c541abb1-69b3-4bc5-8430-5e09e5239cc8	Host or Folder	com.dotcms.contenttype.model.field.HostFolderField	\N	text2	t	t	f	hostFolder	2	\N	\N	\N	\N	t	f	t	f	2020-03-26 00:35:06
c623cd2f-6653-47d8-9825-1153061ea088	c541abb1-69b3-4bc5-8430-5e09e5239cc8	Title	com.dotcms.contenttype.model.field.CustomField	\N	text1	t	t	t	title	3	$velutil.mergeTemplate('/static/htmlpage_assets/title_custom_field.vtl')	\N	\N	\N	t	f	t	f	2020-03-26 00:35:06
a1bfbb4f-b78b-4197-94e7-917f4e812043	c541abb1-69b3-4bc5-8430-5e09e5239cc8	Url	com.dotcms.contenttype.model.field.TextField	\N	text3	t	t	t	url	4	\N	\N	\N	\N	t	f	t	f	2020-03-26 00:35:06
bf73876b-8517-4123-a0ec-d862ba6e8797	c541abb1-69b3-4bc5-8430-5e09e5239cc8	Template	com.dotcms.contenttype.model.field.CustomField	\N	text5	t	t	f	template	5	$velutil.mergeTemplate('/static/htmlpage_assets/template_custom_field.vtl')	\N	\N	\N	t	f	t	f	2020-03-26 00:35:06
94a72dbc-fa3d-4de0-b8ab-e9f5d6d577e6	c541abb1-69b3-4bc5-8430-5e09e5239cc8	Subtitle	com.dotcms.contenttype.model.field.TextField	\N	text13	f	f	f	subtitle	6	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:06
95439019-2411-446b-823d-9904b2d188d1	c541abb1-69b3-4bc5-8430-5e09e5239cc8	Image	com.dotcms.contenttype.model.field.ImageField	\N	text11	f	f	f	image	7	\N	\N	Used in Banner or Breadcrumbs	\N	f	f	f	f	2020-03-26 00:35:06
d8a7431e-140d-4076-bf07-17fdfad6a14e	c541abb1-69b3-4bc5-8430-5e09e5239cc8	Friendly Name	com.dotcms.contenttype.model.field.TextField	\N	text7	f	t	f	friendlyName	8	\N	\N	\N	\N	t	f	f	f	2020-03-26 00:35:06
fa5ddfd5-4a3d-4cc1-8358-255497e16b8e	c541abb1-69b3-4bc5-8430-5e09e5239cc8	fields-2	com.dotcms.contenttype.model.field.RowField	\N	system_field	f	f	f	fields4	9	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:06
97f0c9f1-8dad-4fae-bab5-8f3826660091	c541abb1-69b3-4bc5-8430-5e09e5239cc8	fields-3	com.dotcms.contenttype.model.field.ColumnField	\N	system_field	f	f	f	fields5	10	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:06
99ac031c-7d72-4b08-bedd-37a71b594950	c541abb1-69b3-4bc5-8430-5e09e5239cc8	Show on Menu	com.dotcms.contenttype.model.field.CheckboxField	\N	text6	f	t	f	showOnMenu	11	|true	\N	\N	false	t	f	f	f	2020-03-26 00:35:06
14534da0-9ead-4667-b4a4-993d33374fff	c541abb1-69b3-4bc5-8430-5e09e5239cc8	fields-4	com.dotcms.contenttype.model.field.ColumnField	\N	system_field	f	f	f	fields6	12	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:06
1677ca4f-e46f-449f-ae59-4952fb567e5e	c541abb1-69b3-4bc5-8430-5e09e5239cc8	Sort Order	com.dotcms.contenttype.model.field.TextField	\N	integer1	t	t	f	sortOrder	13	\N	\N	\N	0	t	f	t	f	2020-03-26 00:35:06
e6a050cb-22fc-4a13-8646-5b60c25f2972	c541abb1-69b3-4bc5-8430-5e09e5239cc8	fields-5	com.dotcms.contenttype.model.field.ColumnField	\N	system_field	f	f	f	fields7	14	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:06
e58d33b7-17e5-4205-a191-4af292381019	c541abb1-69b3-4bc5-8430-5e09e5239cc8	fields-6	com.dotcms.contenttype.model.field.ColumnField	\N	system_field	f	f	f	fields8	15	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:06
0ef91b42-2fdf-4711-b9e6-a9a0cf389632	c541abb1-69b3-4bc5-8430-5e09e5239cc8	SEO	com.dotcms.contenttype.model.field.TabDividerField	\N	system_field	f	f	f	seo	16	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:06
29175adc-271b-4691-ab7b-b40d11e8e408	c541abb1-69b3-4bc5-8430-5e09e5239cc8	fields-7	com.dotcms.contenttype.model.field.RowField	\N	system_field	f	f	f	fields9	17	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:06
2a083fcb-ceba-4daf-a6e3-405cd27f1620	c541abb1-69b3-4bc5-8430-5e09e5239cc8	fields-8	com.dotcms.contenttype.model.field.ColumnField	\N	system_field	f	f	f	fields10	18	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:06
95b191a7-a28e-463f-bb0f-e0d36fb40022	c541abb1-69b3-4bc5-8430-5e09e5239cc8	Canonical URL	com.dotcms.contenttype.model.field.TextField	\N	text10	f	f	f	canonicalUrl	19	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:06
5971d5e7-3119-4c3e-b01d-0641aca79977	c541abb1-69b3-4bc5-8430-5e09e5239cc8	SEO Title	com.dotcms.contenttype.model.field.TextField	\N	text12	f	f	f	seoTitle	20	\N	\N	The page title should be 55 characters or less. Try to use primary Keyword and secondary keyword separated by a dash in the title.	\N	f	f	f	f	2020-03-26 00:35:06
dfc5f28d-d47e-4007-869a-f2d5cfbc3d39	c541abb1-69b3-4bc5-8430-5e09e5239cc8	SEO Description	com.dotcms.contenttype.model.field.TextAreaField	\N	text_area1	f	t	f	seodescription	21	\N	\N	The SEO description should be 150 characters or less. Do not use quotes or any non-alpha characters.	\N	t	f	t	f	2020-03-26 00:35:06
f00b3844-820d-4967-9f8e-0cce68d22b13	c541abb1-69b3-4bc5-8430-5e09e5239cc8	SEO Keywords	com.dotcms.contenttype.model.field.TextAreaField	\N	text_area2	f	t	f	seokeywords	22	\N	\N	\N	\N	t	f	t	f	2020-03-26 00:35:06
1aa4bbc6-d30e-4b43-8f13-d6e8f2a58a52	c541abb1-69b3-4bc5-8430-5e09e5239cc8	Advanced Properties	com.dotcms.contenttype.model.field.TabDividerField	\N	system_field	f	f	f	advancedtab	23	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:06
d59ffe8d-7f46-4b68-a243-dbbd3be11f74	855a2d72-f2f3-4169-8b04-ac5157c4380c	fields-0	com.dotcms.contenttype.model.field.RowField	\N	system_field	f	f	f	fields0	1	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:14
2b97316e-6801-4b61-9dfd-960fc2986380	855a2d72-f2f3-4169-8b04-ac5157c4380c	fields-1	com.dotcms.contenttype.model.field.ColumnField	\N	system_field	f	f	f	fields1	2	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:14
ec8cc36f-6058-4ab5-9bfb-fc36ab011ee5	855a2d72-f2f3-4169-8b04-ac5157c4380c	Host Name	com.dotcms.contenttype.model.field.TextField	\N	text1	t	t	t	hostName	3	\N	\N	\N	\N	t	f	t	t	2020-03-26 00:35:14
01f23a87-9859-4860-8368-f70a6ba9687f	855a2d72-f2f3-4169-8b04-ac5157c4380c	Aliases	com.dotcms.contenttype.model.field.TextAreaField	\N	text_area1	f	t	t	aliases	4	\N	\N	\N	\N	t	f	t	f	2020-03-26 00:35:14
cf5d08aa-7ff0-4fc8-a6ac-5a36e82cd741	855a2d72-f2f3-4169-8b04-ac5157c4380c	Tag Storage	com.dotcms.contenttype.model.field.CustomField	\N	text4	f	t	f	tagStorage	5	#parse('static/tag/tag_storage_field_creation.vtl')	\N	\N	\N	t	f	f	f	2020-03-26 00:35:14
c4628fad-9122-404a-8248-faaac4e6c29f	855a2d72-f2f3-4169-8b04-ac5157c4380c	Is Default	com.dotcms.contenttype.model.field.HiddenField	\N	bool1	f	t	f	isDefault	5	true|true\nfalse|false	\N	\N	false	t	t	f	f	2020-03-26 00:35:14
a0712c61-06ec-4019-a148-21d53fe05f92	855a2d72-f2f3-4169-8b04-ac5157c4380c	Is System Host	com.dotcms.contenttype.model.field.HiddenField	\N	bool2	f	t	f	isSystemHost	6	true|true\nfalse|false	\N	\N	false	t	t	f	f	2020-03-26 00:35:14
8377586d-ac40-43b9-81ce-55b64f24433b	855a2d72-f2f3-4169-8b04-ac5157c4380c	Host Thumbnail	com.dotcms.contenttype.model.field.BinaryField	\N	system_field	f	f	f	hostThumbnail	6	\N	\N	\N	\N	t	f	f	f	2020-03-26 00:35:14
2f00a11d-f64c-4f8f-8126-238cc01fbf96	855a2d72-f2f3-4169-8b04-ac5157c4380c	Run Dashboard	com.dotcms.contenttype.model.field.RadioField	\N	bool3	f	t	f	runDashboard	7	Yes|1\r\nNo|0	\N	\N	0	t	f	f	f	2020-03-26 00:35:14
4e01f028-dbf8-41f6-8c3d-92c89e00ddbd	855a2d72-f2f3-4169-8b04-ac5157c4380c	Meta Data (Default)	com.dotcms.contenttype.model.field.LineDividerField	\N	system_field	f	f	f	metaData	8	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:14
bca1a66b-4ab0-44aa-b73c-502390d4b4f1	855a2d72-f2f3-4169-8b04-ac5157c4380c	Keywords	com.dotcms.contenttype.model.field.TextAreaField	\N	text_area3	f	f	f	keywords	9	\N	[^(<[.\\n]+>)]*	Use comma to seperate keywords	\N	f	f	f	f	2020-03-26 00:35:14
af75bdd6-21b9-451f-9fb9-abc763dbf4b1	c541abb1-69b3-4bc5-8430-5e09e5239cc8	fields-9	com.dotcms.contenttype.model.field.RowField	\N	system_field	f	f	f	fields19	24	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:06
3c63301e-1f8f-4f5f-b3a6-736a95d69d4d	c541abb1-69b3-4bc5-8430-5e09e5239cc8	fields-10	com.dotcms.contenttype.model.field.ColumnField	\N	system_field	f	f	f	fields20	25	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:06
c50906a6-dafb-4348-a185-a9334448813c	c541abb1-69b3-4bc5-8430-5e09e5239cc8	Page Metadata	com.dotcms.contenttype.model.field.TextAreaField	\N	text_area3	f	t	f	pagemetadata	26	\N	\N	\N	\N	t	f	t	f	2020-03-26 00:35:06
ae8e673e-1c4e-4333-9cbe-d5dd73687d71	2a3e91e4-fbbf-4876-8c5b-2233c1739b05	fields-0	com.dotcms.contenttype.model.field.RowField	\N	system_field	f	f	f	fields0	0	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:08
afcc3e3e-cb69-4e55-a131-a1f156ad06cf	2a3e91e4-fbbf-4876-8c5b-2233c1739b05	fields-1	com.dotcms.contenttype.model.field.ColumnField	\N	system_field	f	f	f	fields1	1	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:08
49c5bd96-d70c-441c-9c5f-7ccaa8e7ff9a	2a3e91e4-fbbf-4876-8c5b-2233c1739b05	Site	com.dotcms.contenttype.model.field.HostFolderField	\N	system_field	t	t	f	contentHost	2	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:08
9f5a97dc-703c-4721-9cce-29478671558b	2a3e91e4-fbbf-4876-8c5b-2233c1739b05	Title	com.dotcms.contenttype.model.field.TextField	\N	text1	t	t	t	title	3	\N	[^(<[.\\n]+>)]*	\N	\N	f	f	t	f	2020-03-26 00:35:08
5c6e0bff-cfeb-44c6-86e2-a0ba40e7b66c	2a3e91e4-fbbf-4876-8c5b-2233c1739b05	Body	com.dotcms.contenttype.model.field.WysiwygField	\N	text_area1	t	f	f	body	4	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:08
d1835d27-32c3-4bb7-8bce-ac893fb36a0e	f6259cc9-5d78-453e-8167-efd7b72b2e96	fields-0	com.dotcms.contenttype.model.field.RowField	\N	system_field	f	f	f	fields31	0	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:12
a1c63fad-5907-44e3-841d-e91c5cdcaa41	f6259cc9-5d78-453e-8167-efd7b72b2e96	fields-1	com.dotcms.contenttype.model.field.ColumnField	\N	system_field	f	f	f	fields41	1	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:12
98e9924d-8847-4ceb-a2a7-19508c3c1106	f6259cc9-5d78-453e-8167-efd7b72b2e96	Host	com.dotcms.contenttype.model.field.HostFolderField	\N	system_field	t	t	f	host1	2	\N	\N	\N	\N	f	f	t	f	2020-03-26 00:35:12
7adb7ed2-4c15-4399-9675-c32f84ba8ff9	f6259cc9-5d78-453e-8167-efd7b72b2e96	Title	com.dotcms.contenttype.model.field.TextField	\N	text1	t	t	t	title	3	\N	\N	\N	\N	f	f	t	f	2020-03-26 00:35:12
2d9bd5ac-ee66-4523-94a7-05897c609a98	f6259cc9-5d78-453e-8167-efd7b72b2e96	URL Title	com.dotcms.contenttype.model.field.CustomField	\N	text_area2	f	t	t	urlTitle	4	#dotParse('/application/vtl/custom-fields/url-title.vtl')	\N	\N	\N	f	f	t	f	2020-03-26 00:35:12
773afa92-519e-4e13-b3eb-9eeb88f9dec7	f6259cc9-5d78-453e-8167-efd7b72b2e96	Dates & Times	com.dotcms.contenttype.model.field.LineDividerField	\N	system_field	f	f	f	datesTimes	5	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:12
61a1f907-a118-4e61-b8e5-7d23a4700681	f6259cc9-5d78-453e-8167-efd7b72b2e96	fields-2	com.dotcms.contenttype.model.field.RowField	\N	system_field	f	f	f	fields0	6	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:12
b8fa0d70-4ea3-447f-a00c-9cc376077682	f6259cc9-5d78-453e-8167-efd7b72b2e96	fields-3	com.dotcms.contenttype.model.field.ColumnField	\N	system_field	f	f	f	fields1	7	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:12
2a918837-0e1f-41b9-8fc0-e8fca2a1bff4	f6259cc9-5d78-453e-8167-efd7b72b2e96	Start Date	com.dotcms.contenttype.model.field.DateTimeField	\N	date1	t	t	t	startDate	8	\N	\N	\N	\N	f	f	t	f	2020-03-26 00:35:12
b7d91b8f-0acb-4da2-bc95-519cf7151eb2	f6259cc9-5d78-453e-8167-efd7b72b2e96	fields-4	com.dotcms.contenttype.model.field.ColumnField	\N	system_field	f	f	f	fields2	9	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:12
28a791c8-67b9-4797-b036-bbad65a57ee7	f6259cc9-5d78-453e-8167-efd7b72b2e96	End Date	com.dotcms.contenttype.model.field.DateTimeField	\N	date2	t	t	f	endDate	10	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:12
413853a4-6a5b-4b84-a2bf-a78a54302bca	f6259cc9-5d78-453e-8167-efd7b72b2e96	fields-5	com.dotcms.contenttype.model.field.RowField	\N	system_field	f	f	f	fields81	11	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:12
b8a1f389-ad7d-41d9-8169-815ae42ec557	f6259cc9-5d78-453e-8167-efd7b72b2e96	fields-6	com.dotcms.contenttype.model.field.ColumnField	\N	system_field	f	f	f	fields9	12	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:12
2e680bab-5486-4db6-aec7-d0954392b1e0	f6259cc9-5d78-453e-8167-efd7b72b2e96	Details	com.dotcms.contenttype.model.field.LineDividerField	\N	system_field	f	f	f	details	13	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:12
4e129616-ee4f-4e7e-a978-a72dbdf1ae64	f6259cc9-5d78-453e-8167-efd7b72b2e96	fields-7	com.dotcms.contenttype.model.field.RowField	\N	system_field	f	f	f	fields72	14	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:12
23cdb91f-e085-4177-ac41-83099d9027c0	f6259cc9-5d78-453e-8167-efd7b72b2e96	fields-8	com.dotcms.contenttype.model.field.ColumnField	\N	system_field	f	f	f	fields83	15	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:12
33e793f0-f1dc-4986-847b-5b0a529b4373	f6259cc9-5d78-453e-8167-efd7b72b2e96	Tags	com.dotcms.contenttype.model.field.TagField	\N	system_field	f	t	f	tags	16	\N	\N	\N	\N	f	f	t	f	2020-03-26 00:35:13
95bdc5e0-0f70-471e-855f-ede8a157c375	f6259cc9-5d78-453e-8167-efd7b72b2e96	fields-9	com.dotcms.contenttype.model.field.ColumnField	\N	system_field	f	f	f	fields92	17	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:13
1f414f9e-362b-4e10-a335-4a3bd11e0ff2	f6259cc9-5d78-453e-8167-efd7b72b2e96	Image	com.dotcms.contenttype.model.field.BinaryField	\N	system_field	f	f	f	image	18	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:13
a92b093b-5d39-4ef7-aaf2-436a1884b491	f6259cc9-5d78-453e-8167-efd7b72b2e96	fields-10	com.dotcms.contenttype.model.field.RowField	\N	system_field	f	f	f	fields7	19	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:13
6a470a84-f5d5-4e4d-b9d7-26d5386d9774	f6259cc9-5d78-453e-8167-efd7b72b2e96	fields-11	com.dotcms.contenttype.model.field.ColumnField	\N	system_field	f	f	f	fields8	20	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:13
ed892f16-a88e-4cdc-b9c3-8324709f8a21	f6259cc9-5d78-453e-8167-efd7b72b2e96	Description	com.dotcms.contenttype.model.field.WysiwygField	\N	text_area1	f	t	f	description	21	\N	\N	\N	\N	f	f	t	f	2020-03-26 00:35:13
8d699885-867b-4b96-bff9-1198e96f8941	f6259cc9-5d78-453e-8167-efd7b72b2e96	Recurrence Start	com.dotcms.contenttype.model.field.HiddenField	\N	date3	f	t	f	recurrenceStart	22	\N	\N	\N	\N	f	f	t	f	2020-03-26 00:35:13
1f4b74e2-d00f-4245-840d-f84297438069	f6259cc9-5d78-453e-8167-efd7b72b2e96	Recurrence End	com.dotcms.contenttype.model.field.HiddenField	\N	date4	f	t	f	recurrenceEnd	23	\N	\N	\N	\N	f	f	t	f	2020-03-26 00:35:13
ea67f7b5-d7b4-4f7c-ae1a-5c008f3a8a16	f6259cc9-5d78-453e-8167-efd7b72b2e96	Recurrence Interval	com.dotcms.contenttype.model.field.HiddenField	\N	integer1	f	t	f	recurrenceInterval	24	\N	\N	\N	\N	f	f	t	f	2020-03-26 00:35:13
314c6664-d8be-452b-acca-d62d908b4a34	f6259cc9-5d78-453e-8167-efd7b72b2e96	Recurrence Occurs	com.dotcms.contenttype.model.field.HiddenField	\N	text7	f	t	f	recurrenceOccurs	25	\N	\N	\N	\N	f	f	t	f	2020-03-26 00:35:13
c46e28fd-38e9-46d2-ab04-168b18cbde23	f6259cc9-5d78-453e-8167-efd7b72b2e96	No Recurrence End	com.dotcms.contenttype.model.field.HiddenField	\N	bool2	f	t	f	noRecurrenceEnd	26	\N	\N	\N	\N	f	f	t	f	2020-03-26 00:35:13
04b1cdea-6c48-4a1b-bf47-6edfd5091246	855a2d72-f2f3-4169-8b04-ac5157c4380c	Description	com.dotcms.contenttype.model.field.TextAreaField	\N	text_area2	f	f	f	description	10	\N	[^(<[.\\n]+>)]*	Used by default in page meta data description field	\N	f	f	f	f	2020-03-26 00:35:14
5ee13991-970e-4a0b-b5e8-6547d7bb3bf2	855a2d72-f2f3-4169-8b04-ac5157c4380c	Site Tags	com.dotcms.contenttype.model.field.LineDividerField	\N	system_field	f	f	f	siteKeys	11	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:14
f41dcc3c-36ce-4ea5-a621-23011936c418	855a2d72-f2f3-4169-8b04-ac5157c4380c	Google Map	com.dotcms.contenttype.model.field.TextField	\N	text5	f	f	f	googleMap	12	\N	[^(<[.\\n]+>)]*	Google Map Key	\N	f	f	f	f	2020-03-26 00:35:14
02d02031-ef53-43f2-9845-6a2a85538072	855a2d72-f2f3-4169-8b04-ac5157c4380c	Google Analytics	com.dotcms.contenttype.model.field.TextField	\N	text6	f	f	f	googleAnalytics	13	\N	[^(<[.\\n]+>)]*	\N	\N	f	f	f	f	2020-03-26 00:35:14
4242af9d-2cc9-440f-a136-c92f1fe0e65a	855a2d72-f2f3-4169-8b04-ac5157c4380c	Add This	com.dotcms.contenttype.model.field.TextField	\N	text2	f	f	f	addThis	14	\N	[^(<[.\\n]+>)]*	Add This Pub ID	\N	f	f	f	f	2020-03-26 00:35:14
f7f559fd-7100-45f5-b4e9-131a9d63984c	855a2d72-f2f3-4169-8b04-ac5157c4380c	Proxy Url for Edit Mode	com.dotcms.contenttype.model.field.TextField	\N	text7	f	f	f	proxyEditModeUrl	17	\N	\N	Set this value to the full url that will receive the page-as-a-service payload as an HTTP POST, e.g. https://spa.dotcms.com/editMode	\N	f	f	f	f	2020-03-26 00:35:14
8f62657b-8915-489c-820e-12e8e272f1c1	855a2d72-f2f3-4169-8b04-ac5157c4380c	Embedded Dashboard Url	com.dotcms.contenttype.model.field.TextField	\N	text3	f	f	f	embeddedDashboard	18	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:14
4825beb5-4f85-4296-bccc-de6243713a98	897cf4a9-171a-4204-accb-c1b498c813fe	fields-0	com.dotcms.contenttype.model.field.RowField	\N	system_field	f	f	f	fields0	0	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:15
a42bdb13-446d-4d8e-bf2c-630b0113a318	897cf4a9-171a-4204-accb-c1b498c813fe	fields-1	com.dotcms.contenttype.model.field.ColumnField	\N	system_field	f	f	f	fields1	1	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:15
be12a0d9-d442-4224-ad78-e7cd14fa7e8b	897cf4a9-171a-4204-accb-c1b498c813fe	Form Title	com.dotcms.contenttype.model.field.ConstantField	\N	system_field	f	t	f	formTitle	2	Contact Us	\N	\N	\N	t	f	t	f	2020-03-26 00:35:15
aa52dcb1-6924-46fa-8236-ba90217a5e2f	897cf4a9-171a-4204-accb-c1b498c813fe	Accept	com.dotcms.contenttype.model.field.CheckboxField	\N	text5	t	f	f	accept	19	|accept	\N	I agree to all terms and conditions of TravelLux Resort Destinations	\N	f	f	f	f	2020-03-26 00:35:15
8303cdf7-9288-4171-9ab7-345bcece0745	897cf4a9-171a-4204-accb-c1b498c813fe	Comments	com.dotcms.contenttype.model.field.TextAreaField	\N	text_area1	f	t	f	comments	18	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:15
f6d72f6a-358b-4ad1-810b-bfad491106fe	897cf4a9-171a-4204-accb-c1b498c813fe	fields-6	com.dotcms.contenttype.model.field.ColumnField	\N	system_field	f	f	f	fields6	17	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:15
819668b0-72fb-475f-b1cb-0656eb53b622	897cf4a9-171a-4204-accb-c1b498c813fe	fields-5	com.dotcms.contenttype.model.field.RowField	\N	system_field	f	f	f	fields5	16	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:15
0ee18c61-75fb-47b2-b7c5-73cdd72da45f	897cf4a9-171a-4204-accb-c1b498c813fe	Email	com.dotcms.contenttype.model.field.TextField	\N	text4	t	t	t	email	15	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:15
584c7d9f-15a6-4ac6-a1ea-50616f68cc94	897cf4a9-171a-4204-accb-c1b498c813fe	Phone	com.dotcms.contenttype.model.field.TextField	\N	text3	f	f	f	phone	14	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:15
251f0fbe-a821-461b-beaf-a1d750f72be7	897cf4a9-171a-4204-accb-c1b498c813fe	Last Name	com.dotcms.contenttype.model.field.TextField	\N	text2	t	t	t	lastName	13	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:15
afb1b271-8177-4662-b3b6-82dcc3ef08d4	897cf4a9-171a-4204-accb-c1b498c813fe	fields-4	com.dotcms.contenttype.model.field.ColumnField	\N	system_field	f	f	f	fields4	12	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:15
79870479-87c9-42f1-b32e-d3c11a5cf0a2	897cf4a9-171a-4204-accb-c1b498c813fe	My Interests	com.dotcms.contenttype.model.field.TagField	\N	system_field	f	t	f	myInterests	11	\N	\N	\N	\N	f	f	t	f	2020-03-26 00:35:15
17c86833-c9fd-4baf-bc99-582f66caee60	897cf4a9-171a-4204-accb-c1b498c813fe	Headshot	com.dotcms.contenttype.model.field.BinaryField	\N	system_field	f	f	f	headshot	10	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:15
5098c65f-2843-4fac-a656-e9fc1309c53c	897cf4a9-171a-4204-accb-c1b498c813fe	First Name	com.dotcms.contenttype.model.field.TextField	\N	text1	t	t	t	firstName	9	\N	\N	\N	\N	f	f	t	f	2020-03-26 00:35:15
dce8e76b-038a-4c7b-811e-0b0541705a8d	897cf4a9-171a-4204-accb-c1b498c813fe	fields-3	com.dotcms.contenttype.model.field.ColumnField	\N	system_field	f	f	f	fields3	8	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:15
1791b949-18bc-40ca-8c42-e2daa59d99cc	897cf4a9-171a-4204-accb-c1b498c813fe	fields-2	com.dotcms.contenttype.model.field.RowField	\N	system_field	f	f	f	fields2	7	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:15
e9a4b604-08e6-4e54-af40-c46397da3142	897cf4a9-171a-4204-accb-c1b498c813fe	Form Host	com.dotcms.contenttype.model.field.HostFolderField	\N	system_field	f	t	f	formHost	6	\N	\N	\N	\N	t	f	t	f	2020-03-26 00:35:15
87e33968-af6b-4f56-ae3b-db58bba7bacc	897cf4a9-171a-4204-accb-c1b498c813fe	Form Return Page	com.dotcms.contenttype.model.field.ConstantField	\N	system_field	f	t	f	formReturnPage	5	/contact-us/thank-you	\N	\N	\N	t	t	t	f	2020-03-26 00:35:15
449cf9d8-f5ce-47e6-bb26-eebe41a14bc8	897cf4a9-171a-4204-accb-c1b498c813fe	Form Email	com.dotcms.contenttype.model.field.ConstantField	\N	system_field	f	t	f	formEmail	4	info@dotcms.com	\N	\N	\N	t	t	t	f	2020-03-26 00:35:15
3df8c272-c74f-4405-8b67-c8dbdf4bedb3	897cf4a9-171a-4204-accb-c1b498c813fe	Success Callback	com.dotcms.contenttype.model.field.ConstantField	\N	system_field	f	t	f	formSuccessCallback	3	// contentlet is an object\n// e.g. contentlet.inode, contentlet.firstName\n\nwindow.location='/thank-you?id=' + contentlet.identifier	\N	\N	\N	f	f	t	f	2020-03-26 00:35:15
b7bfe31d-60d3-4375-94fb-2a5304bbd67a	33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d	fields-0	com.dotcms.contenttype.model.field.RowField	\N	system_field	f	f	f	fields0	0	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:15
f0606fef-fbd1-40f9-9a0b-873399878166	33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d	fields-1	com.dotcms.contenttype.model.field.ColumnField	\N	system_field	f	f	f	fields1	1	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:15
9e194425-7cea-45b1-81b9-aa53b4f9641e	33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d	Host Or Folder	com.dotcms.contenttype.model.field.HostFolderField	\N	text1	t	t	f	hostFolder	2	\N	\N	\N	\N	t	f	t	f	2020-03-26 00:35:15
f07d5eeb-609c-414a-83c7-948fce643e99	33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d	File Name	com.dotcms.contenttype.model.field.TextField	\N	text3	f	t	t	fileName	3	\N	\N	\N	\N	t	f	t	f	2020-03-26 00:35:15
468512c0-423e-4f1a-b94c-7cf8b064260a	33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d	File Asset	com.dotcms.contenttype.model.field.BinaryField	\N	system_field	t	f	f	fileAsset	4	\N	\N	\N	\N	t	f	f	f	2020-03-26 00:35:15
f49faf40-ae06-48b4-8801-cf169c9d2eb7	33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d	Title	com.dotcms.contenttype.model.field.TextField	\N	text2	t	t	f	title	5	\N	\N	\N	\N	t	f	t	f	2020-03-26 00:35:15
3bceabd2-a59d-4ad7-86f2-b557bfc205bb	33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d	Metadata	com.dotcms.contenttype.model.field.TabDividerField	\N	system_field	f	f	f	MetadataTab	6	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:15
a0b83168-34e1-4c53-adcb-6996e6bae567	33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d	fields-2	com.dotcms.contenttype.model.field.RowField	\N	system_field	f	f	f	fields2	7	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:15
ae82aadc-d38c-433a-82f6-e2cdad9d7b03	33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d	fields-3	com.dotcms.contenttype.model.field.ColumnField	\N	system_field	f	f	f	fields3	8	\N	\N	\N	\N	f	f	f	f	2020-03-26 00:35:15
c6960e09-8eb1-431e-8a5d-fa22d91cd6f1	33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d	Metadata	com.dotcms.contenttype.model.field.KeyValueField	\N	text_area1	f	t	f	metaData	9	\N	\N	\N	\N	t	t	t	f	2020-03-26 00:35:15
b889dbf8-5e2c-4537-9f2b-024892cf2928	33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d	Show On Menu	com.dotcms.contenttype.model.field.CheckboxField	\N	text4	f	t	f	showOnMenu	10	|true	\N	\N	false	t	f	f	f	2020-03-26 00:35:15
46c9ead3-f501-42ca-9ac6-289ef109809f	33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d	Sort Order	com.dotcms.contenttype.model.field.TextField	\N	integer1	f	t	f	sortOrder	11	\N	\N	\N	0	t	f	f	f	2020-03-26 00:35:15
280f79fd-2c84-4840-8672-0651558974bd	33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d	Description	com.dotcms.contenttype.model.field.TextField	\N	text5	f	t	f	description	12	\N	\N	\N	\N	t	f	f	f	2020-03-26 00:35:15
f231c8a7-9606-4823-8185-6e2172fd5506	f6259cc9-5d78-453e-8167-efd7b72b2e96	Recurrence Dates to Ignore	com.dotcms.contenttype.model.field.HiddenField	\N	text_area4	f	t	f	recurrenceDatesToIgnore	27	\N	\N	\N	\N	f	f	t	f	2020-03-26 00:35:13
5074b1c3-0bc3-495f-be95-72c82d749a67	f6259cc9-5d78-453e-8167-efd7b72b2e96	Recurrence Day Of Week	com.dotcms.contenttype.model.field.HiddenField	\N	integer3	f	t	f	recurrenceDayOfWeek	28	\N	\N	\N	\N	f	f	t	f	2020-03-26 00:35:13
b48eb11e-8de0-417d-a768-46fa4d0e0b5c	f6259cc9-5d78-453e-8167-efd7b72b2e96	Recurrence Month Of Year	com.dotcms.contenttype.model.field.HiddenField	\N	integer5	f	t	f	recurrenceMonthOfYear	29	\N	\N	\N	\N	f	f	t	f	2020-03-26 00:35:13
1da87215-92d1-499c-aeda-517d54114ead	f6259cc9-5d78-453e-8167-efd7b72b2e96	Original Start Date	com.dotcms.contenttype.model.field.HiddenField	\N	date5	f	t	f	originalStartDate	30	\N	\N	\N	\N	f	f	t	f	2020-03-26 00:35:13
74715ca5-6f1c-4580-b511-f91dbe5ad703	f6259cc9-5d78-453e-8167-efd7b72b2e96	Recurs	com.dotcms.contenttype.model.field.HiddenField	\N	bool1	f	t	f	recurs	31	\N	\N	\N	\N	f	f	t	f	2020-03-26 00:35:13
a8ee0bef-3f5b-4572-9a24-c4d0112548c4	f6259cc9-5d78-453e-8167-efd7b72b2e96	Recurrence Days of Week	com.dotcms.contenttype.model.field.HiddenField	\N	text_area3	f	t	f	recurrenceDaysOfWeek	32	\N	\N	\N	\N	f	f	t	f	2020-03-26 00:35:13
40f1dd0a-d4dd-4ce7-abef-0bc1ce711bb4	f6259cc9-5d78-453e-8167-efd7b72b2e96	Recurrence Week Of Month	com.dotcms.contenttype.model.field.HiddenField	\N	integer4	f	t	f	recurrenceWeekOfMonth	33	\N	\N	\N	\N	f	f	t	f	2020-03-26 00:35:13
5a3bcf8b-0939-4996-b8c8-57bc76ad5fef	f6259cc9-5d78-453e-8167-efd7b72b2e96	Recurrence Day of Month	com.dotcms.contenttype.model.field.HiddenField	\N	integer2	f	t	f	recurrenceDayOfMonth	34	\N	\N	\N	\N	f	f	t	f	2020-03-26 00:35:13
cf46e80e-7b1f-40b1-b9c7-fb837af60d38	f6259cc9-5d78-453e-8167-efd7b72b2e96	Disconnected From	com.dotcms.contenttype.model.field.HiddenField	\N	text8	f	t	f	disconnectedFrom	35	\N	\N	\N	\N	f	f	t	f	2020-03-26 00:35:13
\.


--
-- Data for Name: field_variable; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.field_variable (id, field_id, variable_name, variable_key, variable_value, user_id, last_mod_date) FROM stdin;
58fcaa6f-226b-46c0-b280-035227b53062	1f414f9e-362b-4e10-a335-4a3bd11e0ff2	1569012946518	accept	image/*	system	2020-03-26 00:35:13
db259182-2193-49ee-9b25-2dcee5b65356	17c86833-c9fd-4baf-bc99-582f66caee60	1567021713628	accept	image/*	system	2020-03-26 00:35:15
\.


--
-- Data for Name: fileassets_ir; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.fileassets_ir (file_name, local_working_inode, local_live_inode, remote_working_inode, remote_live_inode, local_identifier, remote_identifier, endpoint_id, language_id) FROM stdin;
\.


--
-- Data for Name: fixes_audit; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.fixes_audit (id, table_name, action, records_altered, datetime) FROM stdin;
039eb94b-5c75-4224-9a6d-dd114915f61b	identifier	task 30: Fixed DeleteOrphanedAssets	0	2017-03-10 11:49:26.858
0a13e807-5025-43b1-8b30-3cdecc994298	field	task 80: DeleteOrphanedContentTypeFields	55	2017-03-10 11:49:21.227
0e126998-9673-4124-9939-1af72a5921df	contentlet	task 10: Deletes the file assets with no inode	0	2010-02-08 00:00:00
118e9b19-4680-4778-a762-5c5018f1cf0a	identifier	task 30: Fixed DeleteOrphanedAssets	0	2017-03-10 11:49:32.363
1234c78c-cf71-4c3a-8d51-997d72de0bb8	file_asset	task 40: Fixed CheckFileAssetsMimeType	0	2015-11-02 12:12:06.652
129c1bad-5636-4275-8a72-33e072739c48	contentlet	Check the tree entries that doesn't have a child o parent in the inode table and deleted them	33	2017-03-10 11:49:21.116
14d5c169-74bc-467e-9715-c571de671765	contentlet	task 10: Deletes the file assets with no inode	0	2009-11-08 00:00:00
171b7e84-c9cc-4a4b-a258-11836e3fa154	field	task 90: RecreateMissingFoldersInParentPath	0	2018-10-05 17:14:57.335
24ec40b0-07b4-408d-9ff2-d63aaaff3095	field	task 90: RecreateMissingFoldersInParentPath	0	2017-03-10 11:51:15.108
2514f863-5929-48ec-9db3-f62cc9bd988c	identifier	task 20: Fixed DeleteOrphanedIdentifiers	243	2014-10-07 08:30:38.263
2df2333d-2a70-48f3-a647-acdc027178e5	contentlet	delete assets with missing identifiers	1	2015-11-02 12:11:23.051
3b2355ca-41fb-41ad-9b52-231b7dcd29ca	contentlet	Check the tree entries that doesn't have a child o parent in the inode table and deleted them	1	2017-03-10 11:50:58.681
42fd8c97-7cdc-448c-bc2c-628e35a85af0	identifier	task 30: Fixed DeleteOrphanedAssets	0	2017-03-10 11:51:25.928
430e3f91-5695-4c7d-8386-3afbeebc12e9	identifier	task 30: Fixed DeleteOrphanedAssets	0	2019-10-25 17:48:35.914
430f805a-af87-4d89-b258-90ba04249716	field	task 90: RecreateMissingFoldersInParentPath	0	2017-03-10 11:49:21.433
5003d82f-dbb5-4650-9169-21a1ee8e697c	field	task 90: RecreateMissingFoldersInParentPath	0	2019-11-06 09:59:16.196
532f4e4f-f26e-44db-829c-1ff2d4acf4c6	field	task 90: RecreateMissingFoldersInParentPath	0	2017-03-10 11:50:58.986
56460a10-5011-4317-9fd4-19f7a44c06c1	identifier	task 12: Update Assets Hosts	340	2010-03-16 00:00:00
6a144ceb-e65e-414d-86b3-169636c952ef	contentlet	task 10: Deletes the file assets with no inode	0	2010-01-05 00:00:00
6ad3ef6e-a309-4f37-81ea-22c47dbe00ab	identifier	task 30: Fixed DeleteOrphanedAssets	0	2017-03-14 08:21:46.025
6dfb7f17-4979-4113-9331-afdefc5fa1fc	identifier	task 30: Fixed DeleteOrphanedAssets	0	2017-03-10 11:50:58.697
6e400ab9-2b59-4c8e-a6b9-1f45816cc39a	field	task 90: RecreateMissingFoldersInParentPath	0	2019-10-25 17:48:35.979
6f76f12b-0320-4d26-a9b5-516eab5dc12b	field	task 90: RecreateMissingFoldersInParentPath	0	2019-10-18 14:13:14.976
71250c7a-553d-4d35-9003-e0ea7ada7c4c	contentlet	task 10: Deletes the file assets with no inode	0	2010-01-14 00:00:00
7616e6aa-c9e2-4cb5-a434-efcc350d6ced	contentlet	Check the tree entries that doesn't have a child o parent in the inode table and deleted them	81	2019-10-18 14:13:14.877
7bbfc0c4-9c8a-496f-b404-909de6abe41e	contentlet	Check the tree entries that doesn't have a child o parent in the inode table and deleted them	42	2015-11-02 12:11:23.106
852e1b1f-7fac-4392-a0aa-46459011d13f	identifier	task 30: Fixed DeleteOrphanedAssets	0	2015-11-02 12:11:26.278
85d46a7f-2f9d-42fa-b969-ea0f4623936a	contentlet	task 10: Deletes the file assets with no inode	0	2010-02-12 00:00:00
8a203ea9-9704-48a5-966b-75c69747016d	contentlet	task 10: Deletes the file assets with no inode	0	2010-02-23 00:00:00
8f7a14c2-dd38-4292-89f6-09efc50fdd18	field	task 90: RecreateMissingFoldersInParentPath	0	2017-03-10 11:51:26.135
96c95f4c-6575-443f-8c39-a53a3ec2bee5	identifier	task 30: Fixed DeleteOrphanedAssets	0	2018-10-05 17:14:57.266
98b40042-8a59-48bd-9352-22cc1842b391	contentlet	Check the tree entries that doesn't have a child o parent in the inode table and deleted them	30	2014-10-07 08:30:37.959
9f01163e-38aa-4cbf-a79c-41d8d104a368	identifier	task 30: Fixed DeleteOrphanedAssets	0	2014-10-07 08:30:41.287
a14917c3-12e3-4355-8675-e935bc9a2df0	file_asset	task 40: Fixed CheckFileAssetsMimeType	0	2014-10-07 08:30:44.306
a1520ba8-42d8-4fbb-befc-bec3ed448b2a	field	task 90: RecreateMissingFoldersInParentPath	0	2017-03-10 11:49:32.57
a32d50da-12b5-4308-a5b0-cb12c0a87840	identifier	task 30: Fixed DeleteOrphanedAssets	0	2019-10-18 14:13:14.921
a87339ee-6593-4113-9c36-251e0626b1f7	file_asset	task 40: Fixed CheckFileAssetsMimeType	0	2015-11-02 12:11:29.337
a8881836-1e2b-40eb-bfdf-df9750c80591	identifier	task 30: Fixed DeleteOrphanedAssets	0	2015-11-02 12:12:03.63
addf4ac8-3f54-4574-87a0-b94e9398a07c	field	task 90: RecreateMissingFoldersInParentPath	0	2017-03-14 08:21:46.246
b01049b5-4691-45a3-9a99-7dfcc3de8c0d	contentlet	delete assets with missing identifiers	1	2014-10-07 08:30:37.912
b3052e0f-4c69-4d13-aed1-959eb3e44102	field	task 90: RecreateMissingFoldersInParentPath	0	2019-10-25 17:48:22.398
b483fcb8-d1b2-4667-86d4-1d6b5a433a5a	identifier	task 30: Fixed DeleteOrphanedAssets	0	2017-03-10 11:49:21.149
b879442c-8c32-43a4-b140-0b0540a730cb	field	task 11: Renaming structure fields with variable name 'host'	3	2010-03-26 00:00:00
bb9ad8aa-1afe-43ed-bc12-3127be634c10	identifier	task 30: Fixed DeleteOrphanedAssets	0	2019-10-25 17:48:22.338
be50b4a1-2a43-422a-8363-27355e604f94	identifier	task 30: Fixed DeleteOrphanedAssets	0	2019-11-06 09:59:15.914
cb5a487c-1203-445c-92b5-49be9875a5c5	contentlet	task 10: Deletes the file assets with no inode	0	2010-01-14 00:00:00
d278da11-85b6-4922-af80-4b09edf1697c	field	task 90: RecreateMissingFoldersInParentPath	0	2017-03-10 11:49:27.073
d3a825fe-3db1-46eb-ab12-2e3d2cc5bb57	identifier	task 30: Fixed DeleteOrphanedAssets	0	2017-03-10 11:51:14.883
e2ba7c12-f17b-43db-8073-f5c03e0dedac	identifier	task 20: Fixed DeleteOrphanedIdentifiers	0	2015-11-02 12:11:23.115
e33e8fd6-0340-4c7f-8a83-59a9e8eba65e	field	task 11: Renaming structure fields with variable name 'host'	1	2019-10-25 17:48:22.286
e8ad8b7a-171e-4ca8-9e8d-0fd593c8de78	field	task 11: Renaming structure fields with variable name 'host'	5	2019-10-18 14:13:14.889
ef7b418a-30a5-483a-a876-959ca8e0fb20	identifier	task 20: Fixed DeleteOrphanedIdentifiers	0	2015-11-02 12:12:00.611
73a9ff43-bb0f-4239-81ff-a8307b67f352	identifier	task 30: Fixed DeleteOrphanedAssets	0	2020-03-26 01:09:15.135
c31bcff7-c0da-4a46-913b-4c2c064935eb	field	task 90: RecreateMissingFoldersInParentPath	0	2020-03-26 01:09:15.16
\.


--
-- Data for Name: folder; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.folder (inode, name, title, show_on_menu, sort_order, files_masks, identifier, default_file_type, mod_date) FROM stdin;
SYSTEM_FOLDER	system folder	System folder	f	0		bc9a1d37-dd2d-4d49-a29d-0c9be740bfaf	33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d	2017-03-07 13:25:58.116
\.


--
-- Data for Name: folders_ir; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.folders_ir (folder, local_inode, remote_inode, local_identifier, remote_identifier, endpoint_id) FROM stdin;
\.


--
-- Data for Name: host_variable; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.host_variable (id, host_id, variable_name, variable_key, variable_value, user_id, last_mod_date) FROM stdin;
\.


--
-- Data for Name: htmlpages_ir; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.htmlpages_ir (html_page, local_working_inode, local_live_inode, remote_working_inode, remote_live_inode, local_identifier, remote_identifier, endpoint_id, language_id) FROM stdin;
\.


--
-- Data for Name: identifier; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.identifier (id, parent_path, asset_name, host_inode, asset_type, syspublish_date, sysexpire_date) FROM stdin;
bc9a1d37-dd2d-4d49-a29d-0c9be740bfaf	/System folder	system folder	SYSTEM_HOST	folder	\N	\N
040d7fdf-fb31-4a92-867b-a67bccdfca29	/	040d7fdf-fb31-4a92-867b-a67bccdfca29.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
052e6ccf-408c-43b7-a9d8-6a9505561ae2	/	052e6ccf-408c-43b7-a9d8-6a9505561ae2.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
0b280c00-834f-4721-a48e-2f4df97607ea	/	0b280c00-834f-4721-a48e-2f4df97607ea.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
0bbbb312-52f7-4993-8af1-a87a9ea5ef2b	/	0bbbb312-52f7-4993-8af1-a87a9ea5ef2b.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
0c556e37-99e0-4458-a2cd-d42cc7a11045	/	0c556e37-99e0-4458-a2cd-d42cc7a11045.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
0cb1654b-90e8-4ff5-b8c1-0dcc0508f6ef	/	0cb1654b-90e8-4ff5-b8c1-0dcc0508f6ef.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
1344e901-59ce-4d2d-96ae-90adcf1a5092	/	1344e901-59ce-4d2d-96ae-90adcf1a5092.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
17dfb289-ee8c-4e88-8cb4-ec036c999174	/	17dfb289-ee8c-4e88-8cb4-ec036c999174.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
1f26789c-c4a9-4ceb-835b-cecdcead54ee	/	1f26789c-c4a9-4ceb-835b-cecdcead54ee.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
22236f46-f887-4c57-ae80-6a929e7bc4c1	/	22236f46-f887-4c57-ae80-6a929e7bc4c1.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
2b457e67-9c94-4cb3-8d1b-422fbe4fd5a0	/	2b457e67-9c94-4cb3-8d1b-422fbe4fd5a0.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
2c69bb81-0f25-4a05-8d10-918b5b40a24b	/	2c69bb81-0f25-4a05-8d10-918b5b40a24b.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
2d0683c7-a8ad-406d-a4d5-ec47899a902b	/	2d0683c7-a8ad-406d-a4d5-ec47899a902b.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
2d0fcd52-e3ca-4f33-91e8-baff8db7b88e	/	2d0fcd52-e3ca-4f33-91e8-baff8db7b88e.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
339be8a8-d6aa-4196-b20e-a0ebc5c82037	/	339be8a8-d6aa-4196-b20e-a0ebc5c82037.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
35fe888d-1555-43ad-b155-080dd7d9b9cf	/	35fe888d-1555-43ad-b155-080dd7d9b9cf.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
3826636b-cc3a-46b2-97c5-ce6bdb377fcb	/	3826636b-cc3a-46b2-97c5-ce6bdb377fcb.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
38bba30b-47d1-4c9c-a6d3-63b6e30b529a	/	38bba30b-47d1-4c9c-a6d3-63b6e30b529a.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
4341f0fd-a456-4d77-83da-a5cd7248624d	/	4341f0fd-a456-4d77-83da-a5cd7248624d.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
46bf0614-73ac-48c5-a59f-fc5b883eabe3	/	46bf0614-73ac-48c5-a59f-fc5b883eabe3.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
48190c8c-42c4-46af-8d1a-0cd5db894797	/	48190c8c-42c4-46af-8d1a-0cd5db894797.content	SYSTEM_HOST	contentlet	\N	\N
4bb72d3b-e572-4910-8fc2-d725279adeb5	/	4bb72d3b-e572-4910-8fc2-d725279adeb5.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
50042108-38ec-48ba-be91-7f4368c8630f	/	50042108-38ec-48ba-be91-7f4368c8630f.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
5227bb4e-7b53-4777-af63-da789c40404d	/	5227bb4e-7b53-4777-af63-da789c40404d.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
5389e6a5-ee91-4164-b6ad-cc4f695f1d84	/	5389e6a5-ee91-4164-b6ad-cc4f695f1d84.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
53fd322d-7f6d-4796-ba88-3880a256f13c	/	53fd322d-7f6d-4796-ba88-3880a256f13c.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
591cc010-2cf8-4da3-b75d-53dee0107062	/	591cc010-2cf8-4da3-b75d-53dee0107062.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
593ef32c-2f01-4277-a6a9-2250fd5bb5fe	/	593ef32c-2f01-4277-a6a9-2250fd5bb5fe.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
5a322949-aca5-4518-9920-fbd4de84a82d	/	5a322949-aca5-4518-9920-fbd4de84a82d.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
5bf7da04-f79c-4a31-8eee-fddc2b157421	/	5bf7da04-f79c-4a31-8eee-fddc2b157421.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
5d585f86-15ec-42a4-9a1a-87e57959cfbf	/	5d585f86-15ec-42a4-9a1a-87e57959cfbf.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
5ff402db-77c2-499c-a7db-a62d31d86cc4	/	5ff402db-77c2-499c-a7db-a62d31d86cc4.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
64269d16-2710-4919-88ec-3b09c89ea004	/	64269d16-2710-4919-88ec-3b09c89ea004.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
6828d30e-b9ec-48c7-b96c-81ef01a0a3b1	/	6828d30e-b9ec-48c7-b96c-81ef01a0a3b1.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
683ea6c2-5d33-4363-8061-c811b1381f25	/	683ea6c2-5d33-4363-8061-c811b1381f25.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
69370958-2898-4d1e-96ad-ab14278ad961	/	69370958-2898-4d1e-96ad-ab14278ad961.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
6ffd89b1-3484-4a17-b5b4-e96ecdc6b4f9	/	6ffd89b1-3484-4a17-b5b4-e96ecdc6b4f9.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
76534a2a-04cd-4fd7-b891-0a1e61b1a859	/	76534a2a-04cd-4fd7-b891-0a1e61b1a859.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
7ca937a7-a2b0-4da6-b8f7-a26dffda3827	/	7ca937a7-a2b0-4da6-b8f7-a26dffda3827.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
8257a204-4cc2-48d6-b73f-189c34aedc2c	/	8257a204-4cc2-48d6-b73f-189c34aedc2c.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
86a1e1fe-c026-49f7-91c9-3fb5a77e0172	/	86a1e1fe-c026-49f7-91c9-3fb5a77e0172.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
9469fbf0-9fc2-451d-94d9-5fbfde5b5974	/	9469fbf0-9fc2-451d-94d9-5fbfde5b5974.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
95e0af1d-bf6a-46ca-b0f7-665b23d00be3	/	95e0af1d-bf6a-46ca-b0f7-665b23d00be3.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
965059bc-25b4-44b0-add8-b6fc5144be9d	/	965059bc-25b4-44b0-add8-b6fc5144be9d.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
968b8147-92ba-458d-9fe1-941d9f7c0415	/	968b8147-92ba-458d-9fe1-941d9f7c0415.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
96e19b30-4f82-4a40-82ed-e8640962be93	/	96e19b30-4f82-4a40-82ed-e8640962be93.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
9ac7acb5-cef0-48fd-8cf4-963059442f2c	/	9ac7acb5-cef0-48fd-8cf4-963059442f2c.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
9b9e7218-e086-4c61-991f-6ec22e7d7a82	/	9b9e7218-e086-4c61-991f-6ec22e7d7a82.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
9ce3e0fd-7578-421b-8241-59f6ed3adbd8	/	9ce3e0fd-7578-421b-8241-59f6ed3adbd8.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
SYSTEM_HOST	/	system host	SYSTEM_HOST	contentlet	\N	\N
a55a982f-2b8f-4672-8a5a-f4560a42ec1d	/	a55a982f-2b8f-4672-8a5a-f4560a42ec1d.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
a9d7d59a-8ff8-4ee3-84c0-e49f6312b185	/	a9d7d59a-8ff8-4ee3-84c0-e49f6312b185.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
aed0ee71-a4b8-4afe-8a14-339f79ec5a6f	/	aed0ee71-a4b8-4afe-8a14-339f79ec5a6f.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
b0457d83-b3aa-46d2-a6f8-cbc553780f33	/	b0457d83-b3aa-46d2-a6f8-cbc553780f33.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
ba1002d7-d4db-4019-b242-8118054051a4	/	ba1002d7-d4db-4019-b242-8118054051a4.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
bca97d30-14f3-418d-8827-a2799c5e9a0c	/	bca97d30-14f3-418d-8827-a2799c5e9a0c.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
c2470fd2-9687-4041-ac58-784894171840	/	c2470fd2-9687-4041-ac58-784894171840.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
c41cf5a6-3312-4e3b-b419-0f7d972f3305	/	c41cf5a6-3312-4e3b-b419-0f7d972f3305.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
c4500d42-30da-413d-aca9-7b56f844a055	/	c4500d42-30da-413d-aca9-7b56f844a055.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
cff6f9a9-d0f3-45c2-9370-dc0457c6bbf0	/	cff6f9a9-d0f3-45c2-9370-dc0457c6bbf0.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
d03bcbfe-b67b-482c-ba1d-24fb5f6c5dc2	/	d03bcbfe-b67b-482c-ba1d-24fb5f6c5dc2.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
d0d0aa0f-8aba-416c-8951-f3e8fe9f20cc	/	d0d0aa0f-8aba-416c-8951-f3e8fe9f20cc.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
d1ec7b30-8e9e-4b3e-b075-9cd9557fee8b	/	d1ec7b30-8e9e-4b3e-b075-9cd9557fee8b.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
dc557d44-d90e-4a3c-ba8f-4cc9ee164fda	/	dc557d44-d90e-4a3c-ba8f-4cc9ee164fda.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
dee9deb8-6ed9-45d8-80d4-efc4614d2113	/	dee9deb8-6ed9-45d8-80d4-efc4614d2113.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
e357b275-3cc8-455b-b7d7-0adaefb51040	/	e357b275-3cc8-455b-b7d7-0adaefb51040.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
ea37dc2f-328b-452f-b05b-265a8a48382d	/	ea37dc2f-328b-452f-b05b-265a8a48382d.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
ea887e3a-1e9d-47cf-995a-ce060ae1fc4e	/	ea887e3a-1e9d-47cf-995a-ce060ae1fc4e.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
ed39ed50-0118-4ac2-b047-a8c0960dbd48	/	ed39ed50-0118-4ac2-b047-a8c0960dbd48.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
f58cf618-df78-481c-b2ce-450bac89273a	/	f58cf618-df78-481c-b2ce-450bac89273a.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
f58f3fd8-7808-4074-b520-8edb531521e2	/	f58f3fd8-7808-4074-b520-8edb531521e2.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
fdc739f6-fe53-4271-9c8c-a3e05d12fcac	/	fdc739f6-fe53-4271-9c8c-a3e05d12fcac.template	48190c8c-42c4-46af-8d1a-0cd5db894797	template	\N	\N
\.


--
-- Data for Name: image; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.image (imageid, text_) FROM stdin;
dotcms.org	rO0ABXVyAAJbQqzzF/gGCFTgAgAAeHAAACTYiVBORw0KGgoAAAANSUhEUgAAAQIAAAAwCAYAAAD6inRCAAAkn0lEQVR42u19CXxb1ZX3e0+SbVmWZNmyZG3WLnnX7i1hspGkFEggTUoICXxQ0o/OMGUvpUw7Xxn6QVsKpcNHYUpYuk5LITBhKJS0kJA0KSQBEkIDLWvYIZCQQBJred85990nP8tanmRZaeZn/ziRkd+7y7n3/O855557LsPzPDNN/yOJBVIB1QEpynxXQd+ro+VUUr+C1i+XlEXKEvshp15lhe1m6XuqMt5RTZJHcokDqi+jbRx9tr4EX7PEDAwM1JYGB1n8POn0LziXrDrnotNWrPzq6Wedfe7IzBPqa96WKtLg0BCz+IwVS0876+yLoD8Xn/rF5XH6N66m7QD+AikS8TgTj8eYRCLBDA0PM3MWLDTOOXF+YsHJp55y+lnnnH3amSv/6bQVq756+opVX168/Kzlc+YvXDj7xPmRufMXGoZnzCDvYRlIWN4gHTfZhO+XSXn6ArxLcGI/Zs09UTln/oLQ5xadtmjJynO+BH3A9l+w6IwVy6DtM6APrcMjI+PbXZpfjMivRCJO6vmHOXOhnoW9808+5SQYS+TVhcgvqPPsk05b8nlsw+x58xsGKI/iYzyq9lhyWK7Yf/wO+slA/Y45Jy6IA80BWgA0F2gExrcT2m04YdZsylNoW4y8y4LcKQV+5q/rWPwo8J8ms+Xk9mA3b/L4ebOvcz981Ur/zjLH6Y/R6dlh8nbyZiCDw/Vt+rWy1rwVf7h69bCu3fbNZmvHBmjTmyZvMAUEPA8ABSnR372EjsJYvNFscz6ht9i/pWxsmpkzHgoZbeDwn7om/SK91XGnzmy9DdrwH0Xodn27fY2m1fStQn2BdkShPT8wuv17gL9HxvdhrP3Qx70tdtcDGqP5DHitXlIOW6St4t9YdYvxRJ3FfpvR6d0DfPgsL68EPh1pcwdearY61qg02oWS4rkqzt8xXrOcUWuyLAce3AXt2AX1fwCUpG2R0kEcv1and4ve4vhxg75lFaNUBfL0mZtYm0JRW1IqFfhp8wUW+GMDSW8omvRF4q82NGpa6DNszdtUBVKqVIy7N/S4NxxP+oBc3X1X0r8pa8BTjmNZFojRaHV6q9v/FV848XQgNsj7owO8P5LgvaGYSCmgpORTpLT4DD7vjwzw9P0dNl/wwiZ9s57jOAaIgzq5gnwQx9cb+G4wMSyUhW0oQoHYEO/uDb8slkEqgLoMbWa3tz96D7RjFNsDfC3Wh2zbA1HS7ueg3aerYFyANVCuMndeKVBiG7VaxurxLwV+bSXvFa5H+jvvw7qiAo+ANrXZOxbU1dcjf9jJzWEli2Vg/7WGVq8j2H0jlP9OgPJKMo5IGTpuaen32H6Rt8H40Cfw3ZMdnT0X6Y1tLqyDFeSew3kj1lv7H5YltbZ7fAu9kTjv7gvznlD0DVV9Q8vxrBHAyDHO7r6N7v4o7wFydPZcVRuNQOBnfaOGMTs9q6HuvwIYAV8jvKs3jJ9JoBRQGiiD3xehDH0On0/C++R5nFyeUOyldrfvbJg848Zx4vAK30Nb/o83HEuBgB+l5RWiUU9/LOUI9OwQ1yaYnYzFG1gKdb6LvKT9KNWHsbb3hpF4L4ACgMHN6iatUmgay0pXW73R5IWyHxT5Be+kZfJKWlca2+eDukBor1coVSyZw2N1lfNDVmqlqo6x+TsvgnZ95A3FsV086dP4tmXytElsF+1HOEV5J4BEOL7fHui6AwAmkVvnNBAc30AgTuhuGPD1OBnphJYr+LwsYOgNI5ggGPCuntD9Tc0ttkKmggQIriECJrSlWB1pAALgV+9OwkbUJvydl6EQu8eArJJ+oICmPEQAEv+p0emxXQpon1Jon/skWDHfpoAp8qtSPqWAL2kUWkew5y7QDlkiYOWAAT4L/wFvtVDGr33hLAAkJzmOGRHYsTzKj6Q90P0zbUtrNyM0kZ0GguMWCAQ+mjpcy2BC76vShC4tWNA3d1/0ry0WWwz7nAsGFQEBTE5YqXZRELgC33MJq/Nk+5KBckYJ0AS7f8BRFRjadg6AZlKiMVWDPxno6yi2HQT5O6QuwgtWHggAcDRoNI1gmjxCtaBkFYA8HyhQQIiiCXHAHuy+WFlXN60RHKdAQEHAfTFqAVWe0KWITCRfdPAji8d/AhUubnIaQZTv6OrdDCCwQvJOtYQAwSCFfDLaHCcYbR2n+yIDPDV70lUXNBBg0GbShnbLLClgF5k5hH+qunoG5swaArQAKFM8htjOI16oy+rrvJYC+jQQHGdAoKQgcAkFgfQUagEFVWFnT4j3xwY/a2m3DlAA4CoEAkLAs49h5T7oFgS02iuhaCbtBe3jEDU5popnKcEmjz/ZoGlSlNpJEPllcftO8wnm0FRoAvm0uwz6fdRNOnWlgozEEYHOTxxTzDSaYiAAQ4vhWAWb9d3mIfgb+r+POyBgKW8BBJZ7BRBI1WDS5J9IggNqD0x2Lx2zSQFBjWlqeQbgjH1vc7jmSXlSQB1g1U3aegDBnRJ7XgawEYdokjpGk+T/x5yJJcEKzTGLJ7CqjG3h7CzkSuzJ5nZQkddZMkVAwLEcEf4yOkWeR1CoUC7HgSFiDADBkxIguJr+rb4IaI5RyX4LK67R3tEDK8chV2+oEtVW6lUfT8IkyshyjBEv+cCrRqvDk+t5ngQQFNIE0pIdhnQVHGeZkvyZfF1JmAMZMHfuwR2AQnNS5JXJ4TyJ8iotcwzFXQCBQnFxZ4eaieFMEVAg4wfvbFVryW4KJ8+nKTyV7Ui9pgm3qjwtVvtcEObzzC7PJUCXwu/nGtqtc+Bv7oZGzXh7VlpTlYFAWP25bPuala1MWDtkWGm9MHZz52+WXOe/6x+/G7jniuv9d198Y/BXqy51/t8TQtrBDnuDe3w4ReWAkP0BIHhcAgSXVNGcIisu8EgFZf/ZPbadVgYACFtqHukEktDYNl1RLUPcKnsP7O1QvtWuihpBipoJuatttX0Ihevqy/I5UwHgonC+pqyr1xaZ10oEio6uvrsQOGT4eTIeYX7ttPk7v9lsal/UqNUvbHM4T7f5Oi+zB7p+7Q0nXkJgwHGW8Cot8ZekfeEE39Jum19CW8kf3dSo07usvsDXYHD/5A3HPkEhzkvh2H5POLbJ4vVfAiqPbcJ+ZZWAAE0AqfD2NcV11wfuPvP+yLb7nx359NXtw/v5Z4cP8c8MH5TQIX7H8Cf4/Ue/j7+06d87f/u1ea2LfZIyFWxpk4G0DwThUqs38FC72/dboPstHv/9wOQPxUGDFft5+P4+oLX49yJ0n80XfEBraI1Lbe3cHQI0PeDZi73CAJcHAmQFIADwotUXvBXKOatR3zwbxme22eU9Fdp+Maxe98IEec8rTqCJqwkBATBJDkLfRwpNoioAQUYQyihd7WJvAD0NtAVoF0zyz7L7/lXYVXALtrIAhiC4UMdTWBf8vhvqOuIpzI+ihDY4CqTBbCk0rmQe1TWoG6C+nTL6QwKZHMHue8Acayhknqq1ukbQMGbBc/8P+vQmiUMY21EiTkhXd2gdp1DKjiFQCADQbIHJcxMI7T4Qct4FgusiSBnO/p7vOwoK7wEgfBtUkKYsCFQBCFjhEVIOrO4NNwR+dulTQ/teeWbkIL918H3+icQb/IbE3gx8pnJpQ+KNNP598+A7BBQAIA7c1fvYrSe2LhZVBPQfsKWCPuz+rrXo3PFQlYxMmFwHmORvhQg1CH9sEBH69LzCJWgDbJOh1eyPDLzrLs85mHL3R3CS74UxXK3RN2sLDrZSCWOtswFIXAmT5wPqvU5JVpIM9PdIq9W+gDZLWSKgqDIgoKAFc+heqAs1TGO9RsM0AMHv9brWtgAA12XQr3cnCQYZAmzQRnuw+6dtdudMjG7FwCxSX6OmocnQ0gmr7DfgmX3l1uUifoIEb3K6zy0AmmLwkB14fbCE7yJD59P+Rq3OSMtTSeRJSllQAMAwtTlc/wzlv0C3ZHHL8Kih3RIuvOiMDSRRQ3FvEezRM3zRxJseCQAQlI4gekZfA9oA9CDQWqDfA70AzyZJMAhMQHwe34UytjebzGI0U91kgIAT2q5oUuiYL9kuH9o2/PGfUaA3DryJAJCCz9STA2+lgfgilMHnNgjgwD899DGCwke/6N/4FV9jjyAYrLJYfDrjCHTdS0I+Jep17gDmU8EnqOQw6QPxIQAC++ICQICxoAwg/NWesrQBuuffG34EAMCSY6pJfBPjJpNgXpnavc7u0CPU5kSHFO71J0EwlxYDgcn6CMg2XziehHe/nGdve9x4ACD4oPxdFYJBRhDU+GHQ6s5kJ+I+K8VhAOE+eOflcurCviAQGO2O7xTgGUcX2m66iJTyXWCZb6nq6pTIY7aQYS8EJo0bT9A6NAAIF6CGAONxB9UGFKXUXrBF6xlnT/81IMACAPSG0ijQILgvgXlwTYvFGgPBNQAxItU1kM9GTbMhCCh4MbyzVYh0EwDEE4kfgon0BTrAXCVAIIKAVqln7u59bPULM5JHUZCBkjKEvyAogPaQfDzxOoDBQX59/OU7/Zpeonop84MB+c5gah80OVxnwEqylJDDuRT6/II4eM6e0C/g+8VAY8/kIaOtYynwa5lG12yVALFki4ZBZNeAgPxNEkIqawsLJs6j8G59dveilFdI2JUgswTGg3N299+CYIICbfEGzqfPKEu4MyoCAhRMDzwPpsrXJe0lUTli1B39nSOrIfxoW4ydUMcBV2+k3C1HErtg9fovoIuiis06bFkmG20n1EUmrL7NHIP5fJhu12Zk9CeJAg5As4bjFBOAQFyNTR3uBABGxpXXRzEeuGAOZMxO91kSQFcWXTjHQEEETxOAWou4W1HU048CDSDwQ6oFjOLKDoDwMaiWl4Fd2ZR3d0CgcWoGIJei1eZYSrSEUJSAiS82mLL6g8upRvD5coCA9AlWL52ymbmnd/3lz44c4v8QfyUDgpyqEAAmAMLjideSfx76EMt9yK/pUwuuek628zLHWXhptWIujHbnyeV4lQU1fuAVUG3bip0LKLpNCR9kQejuu6mju+9qWFUoCJTCkoqAgK54kZ0wD5Q0FJgtUQ8BA6s3eB1dUVPl7PMDbRI2mRglU7pTKvRHd3T23ipEVsqqK0njI/5TWdcwYRtZBAJYCEKoOZQAgqx5hnEQpg7XeWQ8JE5HccwKW9Py5wB5EOylq1BAAQSOoAC7+8M7DRZreFxAy1ilbJ4KOSn6wWTUA5jcScEgBWUf1reZQmaXZ0QuEAixAZyinlMzd/etP//ZkU95EFrQAN7OVAkEsgTaxeifBwEMEq/+qksTFh2I+bZBOaqiEeLybB/Sv9VLnytEeQcRvkfbHcq6Q65ZQFTeUJyHlWaJsCCwigpBiBVMTXIaULZjqUIgIKunzdd5sdzYC3HiN5stXZJwYVlAgO1qd/vOpcqGUmafOKhrGOpKyRBaaaTnfcq6+nyquHBcW93ohvlytAznpmiG/hHU/aXwvjoHMwuDAp0QJQNVYAWfB5pAWtQEQECfadTqTLJVy4nuBqXgEFExoFFcg6qfSxD85+FzJdZB6ykKBLhJj2CwwvKVoZ0zDh/+4xSBwBgYvDa6bXg/f39425XUJCkZMz4FAUWCV1mtboCBf16mfUqFLrpZJUw+rrJDcBODXsoY9HKBICM4sRKjuhZjjM4bhVz+gJCp4H25voIM3f48CmqyZ6IpVtRvhs7KBoxOlFlXKSBgqQmm8YZiL5bhf8hQ80QEhL/ZA13fbzFbR0BLUOVYluKiLVsN5MC21/piA38BAc24CGrG3mvU6TylnENyA5FwZQFt4ybR8QgAsBcoXQoIqGrOudUBzfbhA89tGNjLT8IfUIaZ8HoK6jtyhet7EaFRxQOypwAIOCFuQxOA1fKofAdVnG+12b806XGrPOSh7LMGKJz+yMA7AAQ6ucIp8kihVDHw/n05wld4RYWxcfaEXgZNq76SuBUwD9bLNA9KAQHDUkcwCPIvYIwz4ilP2SceKSBgezA2APr2jC3QdU2LxRYFUGBzHMRcqZGrwyQItkDnZV5U30EbQCefxeNfUa3JRAdW0ajTK0HoN4qaQGkgIEaBokmhZ37e98TlWwc/4AEIklMMAoRwV2ETfEKdj7jUATESsWZAkI0663DLjTojq50/OnBI29LqLLk99HcEBBgz4OoJ7UGnc5k/KjSdOrr7b5cJBCkKBJs5IS9JOUBAtKuOrr5fVhMI8LPVaj8J/QQVBl+lae4IemYjRnIjwGK+Gc+jaFuMNsk0UDBF4v9ZtVarB3v9VQABIpjO3tDjoAax5cUgy5sgRntHnzea+JREsJUAAo4RBivY2K/fPrR/L8YG1EAbkJgIr6efGT6U/rb3xydQ7URxDIDgQvkCFUGBerYCgTqmQICT1x7ofq6CulSCIDlu9gkON7lAsJ4by8pTLhCsoUCQnCwQiOVixKi7N7Ixx5lZWe4ICSjQLep9jmD3rbpWY494yrCQ6cVivIBXsN+TuGXYau9YVE74YRkjh7mRwETouh1NBPeYLyIvEChYzPdSx3zHf8fqHcMHeNz3rxUIEK0g8WYKtZC14R2/wC1LFpWCAvNmCoBAPGX4bzIFisQNgPl1b278//EABI5gz2SA4Ac1BII7qgkEkt2DiC868Jm7sjMkhSJKybkC5C+MxSGYkzdqDa2G3KhhhkY2MY7O7t94w2CjkCi02CugIWgqsZ9k+gtYTbMhBBrIqJtqIPmAgG4ccwaVkd048NZjmwTnYE2BAH0FoBXwz458+sFI84kmCk5sjYHghzIFKknrvX0aCI4fIMgGjZEQcu8yUOvTFZwlKZmhyEUjNqHtr8KcWsDlJpVpsVgtIIx/pQLJO7p676RMUkzBLCH/AmM4MD+2CNuT+YFAPEew3PK/rduHDxwCbYAIZo2BAEOV0WnIX+O7/dRi5sEUAsG/lwkEP54GguMMCEQFGMpvd3m/4IsM7J+CjFMACAJ/oPykzdd5HsdJ5LzZ3H42COMnwvkAMAtsjgum1OMsThS39/picQRKVkmeu9x1/aJdI0fQXq85CIhAsG34Y/6evj9cS1yXtQeC75djGkC9P58GguMSCETvPmYv7oH31kuS0KYrPAVZMOAMy7b5O5cLfABNvaO77wf0XEAGgaCtwzVrSvwDOUDQ7vUvKQEERBAu7PjXq3aOHEYgSB0rIECN4NbuB9ZSjYCrMRB8o0wg2DglZt00ENQCCLLPqerqWaPNcTbI5Q6vmJS2eqCQxnwWoBkc0Le1dxIeuEPRX40dEIrzOmNbYEq3nuhEadQ3DwiIR4DgdSkQkGBisCB0SgPzX9Hnbt0y+B4I5ZvJYwEE6DDcQhyG259uq2sv6DCcql0Ds8u7qpz9eHgW4z/0Ze7HTwPB3w8QMNI9f2VdXR1o6YsxVgJs/AMkXkBy1JnWU4H5EE554BMUgXsVeAgJhPBhAALiKARQOAoVO6dUtaSdrG/U9MBEOVIICJBxLao2ZsPAGz/dPPD2MQMC3K7EA0m7Rg7vmtG8QPRf1AwI9G3mISpQGVkn6iKJDKwkCxhJZOc0EBxnQDAWfpN9R6FSMU3NBpupw/W/oP2/9oRi75Fj8P2x3DssMmWEK+N8OWIwtfcy/mh8vQQIDtcKCBo0TV0wUT4rAgScQdXKrI//7ZebB945pkCAJxyfGT64e1A/hyu0czBVkYWq+nozDPr7MnPtkZh9dPgykpwN1RLuaSCoKRCMtY+edciCAljNTYYWQ6vVfqrNF7wF6ngRA5IkSVRSMnM/JMnJUo//qwyYBGuJadBPcgdkmgytvloAgVqrC0MjMkWAQNmiMjGbBt9Zs+nYagSpDYm9mLNgR0xH4orYWmgEYrF1ajUD4/MHmYktMzQzziFYPXx0VZnMOErPGbDTQFATIGDLyTWAX2GWI4PZMs/m77wT+HCI5qFIywACEpJudrrXMCD8d+Q4C2fUwkdgdnvnF3MWciynauDUzI+6fvvdbUMfYzBR8ljuGtzR88jDGGJcK2ehlFcWD0kRJzcEVZzsa+sbG4X6K/EViAf1YRIbbR0n0DwS7BQcQ54GAnEK4b2P4qaUjFwDlNdK6fY8aArBjs6edbSNaVkO5mD3wxjEcBUAwagIBKBuTO2BlTEguFTO9uGFHf/65edHjpJw32MHBPv5O3sfvamWcQRiqfivrrUtSMwo+Tn/0/TGnSuybZAP7KwkOQlO/OswlRp8foNO6KLAMg0ElQUUCYDv/xe0//VGk1QW5NyWJIKCgjoYOeDFY+7SZyJSNAXaY4zB3D4CQPC2u1/IcGsPdt/OjSVsmIqAIgXJ3NrT96CcgKLzbJfFMHMQDSg6ZkBwQ/DnKygQKGsIBKRKFEgoc10ZsejoCCJeYas3cEm9mFVaOJYq2JuscEGF5JOTTtbmNrPF2d2/1ivcd0jy4IMQXKUqAQbTQFB2iDH5vtnU3odg7xHOCPzV7PKsqh/LBl74eoCJ5aHqxkJ5y2jCk1Qx04DkgfB3/o7RGdsUzt7QVoIeQojxS3WNjWqmzHPoZaibbKNObwFt4EPRSVkkxJgx1rU3Pjn49sui467WIcaPJ17jd844fHBWy8keKUDVyEeQXS3aHK659IRaugyvcMYnJK28G3jeIae6Bk2Tut3lXQ2T8Q1JAtOMeKEoCMIVEjCYBoLJAYGQFUyt5gBsN1J+HxWTj8D/Pw5jcTKMSW7QkZhrkssmG2GzadxIZUa780yPEJCULO0j8PySlGzzB79NDx2Norpucno+NyVBRUI2HsbqC1xS6tCRGEtgUBmZ/47uvgVjCWhi0hrHELzPr4vsehQdlyxOhhodOsrRojg8X+7piz5cZhy6kMQC8w6GYh9afcFbWtptc2GlsTdoNPW44sCnCj5NzSZzHLSHq6Htu7ziTbzjbcwsGICmcCk94ajMXaSmgaDcY8ggD17/RTm8Sou/0wS3m8wu77lqrdaiUJSeThp9swp4Wvo0IwUCi9t3HXkRbJJeAIAjePqQCuYjderGqm0/SRjOwcrUjEee6RHkVPHTh0qy+q60XJjYOfJZqtZhxpgVGe9D+F7gp0uL+QemFAgkjjtti7HXFx047JaZQDPnAo+x23FCsQ+Angfajjn1gd4it+WImZgLx7hLweAizGnITMzFNw0EMoBAdMaDCu8DTe9AgaSo2YtXhLFLvAN8+g0A9vn6NnNC3aS1AqmBFEANQB1tDuciT3/kSY+c7WYKBEZbx0piN+Ikhol7H01MkkStAGyURazMnG7lDBrYIzdSbUBuYhIOIwwfiuxah6tzDbWCNKZIf3roo53dTdE6Qe8qmZjkCQkQ/EvVgECciMIlJ1d6xTTj5R86SRU0LXDCyTvkQrQMCgb/RDUDbhoIygICYhLgro6rJ/w7TMxS6nITHDvhSHFUmg7/Xby0BtO6A+0B+rCMy1+I6QjPf9LYpPNlmaltNYbxaDACAe4g+KKJ13VGo5lO8slqBqQOk9N9GlScpqnK9slJVaaguwcrLP8Y3zXj6OgfE6+manEK8fHE60k8Y/Ad/5pFFJIUxddsAgQPiUBgD3bfPOb1rZ6jFfjEQvkP0MEcnWQSC1HwK7kXgASjABispkdauWkgkAcE7NguwTklHXp5jhTT+yr5AiRzPMPi2ZS1El5gJ0Er6Or9Hl2tj7hBO3D29v+xXt3YINnXLHukhBWRZUDDmOONJD6hl56gaXCBnOSlYgZjrbKZWRvefi2s0FMeU7Bh4HWS1vx30b/cjYlRhEzGReeLggLBj93CHXboad9CL8DkquVzpYEmeHuuHurZSreHRqt0TLWC25Dj+3WtbfOlAWjTQFASCAifNLpmMAlin9I2TzYrUbrMS1szmFHcB4uy0e6cOcF+Vzc1qUFQ/0QEFMAArzgDMHgUtAWThBmlbu4Vo9mEy9VAQAAEloGG8QlUjpekZFostjntbu+Q3HTmeM8xOupsDa66R2J7HkPHIV5KMjUgsDe5efBdzFX47HDzvGZSfYm7DUTzCfp1PskX1xNKw+eo0eqISydsEd+JkpEfuSeEaDdp2z190afdgqc5WUMQIHUBqO+zevyzcqNQp4GgOBCIYK5rMXaAeUUToVY1EYmc0OJRt3Dp7e25pl12gmlbWjv88cGX6RVnhxEU/LGBvxjtHfNzPMS4A6CU5OZX5trDmArd2dP/I5K5uDeU8YDg2zu7L8e/ARCUdcGJuG23rP180+6R0WfxIFC1wQA0jVEEgS2D778yqJ/jEUa/9C3JYkiovs1s86HWQyc/fP6pXq2W3oarpDxT5gp/OYGcWTDQaFtxJwEFSXI8daomUEYUNNAEXtG1GmP5fEjTQCDbR4DnSBibL3gl8Omg5DRhtW96ngACws3Xka31jRotBYEJWz+ks20Opx+0gd1uwXlITgii0ILde5+h3ToP87uzBbJ74ykpfZvJA4L+DSjjdY9QBu+NJnAArqK7ERzYR2VfeSbuIpxjvci6e0ZyMzoPH0+8lqpCfEEay6EgsHNAP9sn7I2pygmzVuDWDgDe9+mdgUdoquk/gaYwQ6FUclKeoaaEh0caNBoTXlBqMFttUlCRDwZNCrDTr8tewlrdrDai+pkUL3WFSft7raG1I7unPR1HMJl7DUjItt5oCsFzD0gSkfBTAAgk/TmNVXgKTH5rqfmWVT1BgB+ktx6R3QQUakxuiteYOTq7/wMm+BVAq4DOBPoKmADfxQMy8M4hGpcgBClF4gfxVli8To0ZfwkqerIzuYeOSrrO4WdB6xLNfeGnfrJ7xig69qQXoMp1JGboycIU3pXwzMghAIH3fpXQ/4NRGuJc9vaoVqcDZm+jqtdRMe88/L7ZHui+uaXd9k2grzs6e74H360D2heIDfEABL0VnPHgBF8uhwlMZpOrwydmtUlXMKHElSkpeqoBBD62eoNXNAqpDgpnwh0DAoxNSRM1dLwdm0tJAII0AMEzkwCCGwAI0pTfxepClTgNQPD7SQDBT4AfWFapusS//7ZEiDENC67HfsyHPjyMfKNgM5lxzDqExZuZKDDfBSCgnzDXcBKNJwUubQq0ytVNTRjssDqYGHoVAQB9BggG+OkDgAjEB8cRmBDjngnEBvG5x0DDCBEjnyNXeJFEjVZf4HPkeQSXSPxtaFwLbQM7sU1jpID2qRR1pAMWtYP5uveGRbtmHt6+c+an/Jbh9/mNg3v5J4feSm4aeislobT0//Hv+Nzmobf55+C9p0b27b6x65dnhvSDZFrUKfCqBw75wBRry4S2KYQr+zT6ZqsvHH+C3JaMq2h/NOODT4zyQ54Qvgj7+UTIgvEh3mh19GAZStAcZNaVrZMTfhiNVqeA8ToHhGKbwPuEUL9ASaBUCaLPREn7/JEBbOsBaOPtzW2mANZBjr8pFAX5oxTH1xu4DvvlJ+UkilIgOsi7e0IvlsNrWpeKgKDD/aPO+DBtc/G66Jg8qaqrY+TMNwlxUB/j6Yv8NABllKxnjNbB3Mb3FfnGkBIWT5bm+gY1Y7I7Z7h6+m+Dd9/GccRyhPlCAsPSdJyScsbQR/sMv2+wuH2fU2uaENGY3DEsudoQyGpQG5ttHZe0efw72oPdabOvkxcomIc6+fZA96cmb+CxxhbjklzkEz91Fttca1ffR+3+zo8swe6d8JWhTIRmRe0lXjerbrXxqhXrup5/bGto3ycb+9/mn+jbC/RmHtrLb+h7i98S+vDTP/S+uuFbtlvP83G9mtw+T2a/n37WNRnNl5o8wRfb/V282dtJKUhJ5GHnPqPTe6+iQVNu//OuLGIblI3aBQZbxx0mT+A1S6CbHxuz4tQOBM9/DG3arDVZLufq1e4CdRRtR4Pe8NUWh3uPwerYDe3YU4ReMNhde6CuByvos3A4SqO9stXh2dNsdTxfoq7dBrtzj95ivyvXXpc7rjqz7VosA8oqVZf49x+Vybux9iiUzcDH01scrltgPHbBuOwnc0nGOMKzR9rcvpda7K5bNK1tc/LJ9bifcDhcihT9fX1MKBRiBoZHmFknLhg8ednyC4HWAK0HehroKaBHgW77/NIzvnzCvBN7B4aGmf5+8h4LZXC55Q7NmNkwc/Yc54xZsztmzJ5jjUZjnIy2jKNIOMJEIzGFv8/L+Pt8zKlDS5gr5/1b4M7F/7XyhbMP3rDtrHcf3LHy/S1AzwBt3X7Wu+ueX7X/hw8t23bO1+Zd071q5mqmsz8AFISyoopoOMqU24YCxIX6+6H//czgyIwG4Nkc4M0/n7x0+U1APwEe3XLKF1dcPf+UxUuh/85IJMKEgb9VqJcl44V10zEbHJnZCHweWbh4yepTlp0J9Z9xP7RhI9B2SpuB/hvadAe06co5Cz+/eObsue54IkHe7+vrxU9FvjEsRvhuuVRxv2tYV236FUFecziGOJZYRmJgkIFx8c6cM3chjNVqGLNrgW4D+hmlNTC2N57yxTMvm3/qaUvg2f7B4REl4Q2WAYRzo1CdDM/zcogFUsh8djLvVEqkrgyfZj/jDzIpfrTo8/Acg88l+aNiG9mpapPMZ7kqt0Gsm/s7KEMuVaPP/9PqEsdgMnIk6/3/D+OCuYsG8TjYAAAAAElFTkSuQmCC
dotcms.org.1	rO0ABXVyAAJbQqzzF/gGCFTgAgAAeHAAAAAxR0lGODlhAQABAJH/AP///wAAAMDAwAAAACH5BAEAAAIALAAAAAABAAEAAAICVAEAOw==
dotcms.org.1key=665518	rO0ABXVyAAJbQqzzF/gGCFTgAgAAeHAAAAAxR0lGODlhAQABAJH/AP///wAAAMDAwAAAACH5BAEAAAIALAAAAAABAAEAAAICVAEAOw==
dotcms.org.2482key=880123	rO0ABXVyAAJbQqzzF/gGCFTgAgAAeHAAAAAxR0lGODlhAQABAJH/AP///wAAAMDAwAAAACH5BAEAAAIALAAAAAABAAEAAAICVAEAOw==
dotcms.org.2662key=113164	rO0ABXVyAAJbQqzzF/gGCFTgAgAAeHAAAAAxR0lGODlhAQABAJH/AP///wAAAMDAwAAAACH5BAEAAAIALAAAAAABAAEAAAICVAEAOw==
\.


--
-- Data for Name: import_audit; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.import_audit (id, start_date, userid, filename, status, last_inode, records_to_import, serverid, warnings, errors, results, messages) FROM stdin;
\.


--
-- Data for Name: indicies; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.indicies (index_name, index_type) FROM stdin;
working_20200326011013	working
live_20200326011013	live
\.


--
-- Data for Name: inode; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.inode (inode, owner, idate, type) FROM stdin;
3909f53d-fd22-45e7-a6dc-7eb8d99fa0b1		2019-10-02 12:25:35.423	user_proxy
5c7d0674-07d6-4f62-b1bc-0e10fe6cb3ba		2019-07-30 10:56:28.135	user_proxy
9eda551c-f698-4976-9f86-db88fecabc1d		2018-12-17 15:58:44.619	user_proxy
f762f699-83e3-466a-95ad-533b37033081		2018-12-17 14:46:37.679	user_proxy
cdb421a2-0a0d-4aad-9b5c-d6cfa6359379		2018-12-17 13:58:15.032	user_proxy
9546b9e0-ba09-4a21-aec7-55a80fb5bdfc		2018-09-25 11:28:27.628	user_proxy
5dc84276-7226-4440-8dfb-16ba56b1afd0		2018-09-24 08:59:52.24	user_proxy
38ff74b9-a772-418e-8c4c-26807d8f8127		2015-02-09 13:07:05.379	user_proxy
097f609b-7da5-402e-8a58-e2a92678223d		2014-09-08 11:58:06.03	user_proxy
07000663-738b-4cfd-990c-364b49f741f9		2014-09-08 11:55:55.23	user_proxy
b7dab462-1533-4f10-91c4-5e824f3fbca2		2014-08-28 22:37:57.345	user_proxy
1b837701-531c-4a5f-b9f1-7b7a62fbd270		2014-08-27 11:43:59.633	user_proxy
cfa80329-12e4-484d-8aaf-568a981d9102		2014-08-20 17:59:22.997	user_proxy
80c762bc-d5b7-4a4a-8132-b07b72a5232e		2014-08-20 17:44:45.564	user_proxy
b01e9978-b28a-4f37-93d9-aebcadf6a230		2013-03-26 07:38:54.14	user_proxy
cafb8edc-a3a8-40e6-8ea8-452ba61d5420		2012-03-06 17:24:14.313	user_proxy
fad56446-b9c1-40ce-aee0-fc63b0c945b8		2012-03-06 08:54:20.103	user_proxy
c84946af-d727-4500-9f61-7522adec00d6		2012-03-05 16:00:51.035	user_proxy
42ae54e6-0ee5-4d10-8a22-cfc009575db6		2012-03-02 15:27:51.375	user_proxy
d7e0acef-1773-4c5b-ad0c-f915c26336e7		2011-12-30 09:23:54.829	user_proxy
3d900064-6801-4e46-bc88-f7fd5c9b1720		2011-12-15 17:28:47.669	user_proxy
a7472d3b-7f3e-40c0-98a4-1c3a4c29d697		2011-12-15 17:28:10.308	user_proxy
943833e9-88db-4a77-9b15-a8a687558074		2011-12-15 17:27:42.619	user_proxy
6d683b06-3a0a-45dd-b4df-6951da8680a7		2011-12-15 17:27:11.208	user_proxy
95450e1f-f553-4eeb-ac86-0fead1c047d0		2011-10-04 15:59:46.863	user_proxy
9f073702-33c8-4b9d-adba-36946ba1ee9c		2011-09-29 14:07:17.667	user_proxy
82be01b1-956e-4808-abf5-68b67c95026f		2011-03-14 11:42:26.816	user_proxy
f314b9ad-6e3d-4265-8db3-fdf78a2cb022		2010-08-20 15:37:46.638	user_proxy
86805713-2607-4f32-a3fb-f7f949f1b6ba		2010-08-12 14:51:06.914	user_proxy
7f3e33dd-b0e0-4651-a542-90e476a249d8		2010-08-11 14:38:23.171	user_proxy
f54bdf6d-4073-4fe2-8d23-d3cfd6594529		2010-08-11 14:31:40.708	user_proxy
37432fed-0c09-4e44-8343-cdfb898e7c04		2010-08-04 15:08:23.025	user_proxy
b0288656-2940-4088-9820-63c341ecae62		2010-05-24 14:58:04.253	user_proxy
13c2374e-f959-47fa-833a-6ae81b8395bb		2010-05-11 12:59:16.325	user_proxy
530af300-0f33-47a6-884b-5f9140c2b8d9		2010-05-11 11:54:44.625	user_proxy
2c3ef021-f9ee-459d-ac57-63e58f592ce3		2010-05-11 11:53:48.495	user_proxy
92b0192f-7e89-4d3b-83a6-df60ca3a11aa		2010-05-11 11:53:05.649	user_proxy
75abaca9-3878-4e4f-b298-eef7de079399		2010-02-25 22:00:53	user_proxy
f74f3681-5ec2-4a2d-8d18-f6f67bee34ce		2010-02-23 22:08:57	user_proxy
1a01290d-9c5f-4351-b812-d31b7504da23		2010-02-23 22:08:43	user_proxy
7aa8b3b5-523d-42ab-b072-7a8c4ad494fa		2010-02-23 21:11:54	user_proxy
SYSTEM_FOLDER	system	2009-10-08 16:27:18	folder
f4d7c1b8-2c88-4071-abf1-a5328977b07d	\N	2017-08-31 16:38:49.714	structure
05b6edc6-6443-4dc7-a884-f029b12e5a0d	\N	2017-08-31 16:38:50	field
c7829c13-cf47-4a20-9331-85fb314cef8e	\N	2017-08-31 16:38:50	field
8e850645-bb92-4fda-a765-e67063a59be0	\N	2017-08-31 16:38:49.349	structure
4e64a309-8c5e-48cf-b4a9-e724a5e09575	\N	2017-08-31 16:38:49	field
3b7f25bb-c5be-48bb-b00b-5b1b754e550c	\N	2017-08-31 16:38:49	field
de4fea7f-4d8f-48eb-8a63-20772dced99a	\N	2017-08-31 16:38:49	field
7e438b93-b631-4812-9c9c-331b03e6b1cd	\N	2017-08-31 16:38:49	field
49f3803a-b2b0-4e03-bb2e-d1bb2a1c135e	\N	2017-08-31 16:38:49	field
9ae3e58a-75c9-4e4a-90f3-6f0d5f32a6f0	\N	2017-08-31 16:38:49	field
4d21b6d8-1711-4ae6-9419-89e2b1ae5a06	\N	2013-12-04 22:00:52.315	structure
31519868-f318-4447-88e7-0ffc2fe4b2cd	\N	2011-07-18 17:24:25	field
8859f1ed-84ad-4105-acda-5d5d29553d9b	\N	2017-06-14 16:30:33	field
d12a2a4f-45f1-4194-95e3-338865e7afde	\N	2017-06-14 16:30:33	field
e5666638-e7f4-4b3a-b6d3-22f8d13188e8	\N	2019-09-13 17:27:48	field
6b33d6be-d197-4f9e-8fc3-d20d36e08c75	\N	2017-06-14 16:30:33	field
c6e3a3c6-a0c6-494b-9ae8-bde7322bc68e	\N	2017-03-07 13:25:58.339	structure
ed1ca7ce-08fb-4a4f-814c-3add0e750625	\N	2018-06-13 15:19:11	field
615957f5-6a44-4952-b321-915c35bbfaeb	\N	2018-06-13 15:19:11	field
3ff698f0-6edf-4cf1-80ee-34fd3e9e3b70	\N	2017-02-08 14:04:27	field
fa7ac3d7-d442-4477-8662-a88885352728	\N	2017-02-08 14:07:20	field
12af029c-217a-45ee-a683-baab61ee7ddf	\N	2017-02-08 14:07:35	field
7d10f7dc-cf0f-405d-ae4b-1d46942b4a8f	\N	2017-02-08 14:04:47	field
848ec05e-2c89-483f-98de-adca6f9a77fe	\N	2017-02-08 14:05:15	field
e59fa37c-29dd-43ab-bbe2-b9bb92036c59	\N	2017-02-08 14:05:34	field
000ef75f-59e2-4c89-9cec-247e371ecd77	\N	2017-02-08 14:07:54	field
48633376-bd98-4f3e-98bb-7616f057a735	\N	2017-02-08 14:06:39	field
c938b15f-bcb6-49ef-8651-14d455a97045	\N	2015-12-16 16:56:43.44	structure
606ac3af-63e5-4bd4-bfa1-c4c672bb8eb8	\N	2015-12-16 16:56:43	field
0ea2bd92-4b2d-48a2-a394-77fd560b1fce	\N	2015-12-16 16:56:43	field
6b25d960-034d-4030-b785-89cc01baaa3d	\N	2015-12-16 16:56:43	field
07cfbc2c-47de-4c78-a411-176fe8bb24a5	\N	2015-12-16 16:56:43	field
2dab7223-ebb5-411b-922f-611a30bc2a2b	\N	2015-12-16 16:56:43	field
65e4e742-d87a-47ff-84ef-fde44e889e27	\N	2015-12-16 16:56:43	field
c541abb1-69b3-4bc5-8430-5e09e5239cc8	\N	2015-05-28 11:26:34.75	structure
fdb123f4-52aa-4ac0-b631-cc0308ca51ff	\N	2018-06-01 16:09:57	field
fb2639d0-c6ef-4e66-8cbd-994a1084614e	\N	2018-06-01 16:09:57	field
23b5f1be-935e-442e-be48-1cf2d1c96d71	\N	2015-01-16 08:51:06	field
c623cd2f-6653-47d8-9825-1153061ea088	\N	2015-01-16 08:51:06	field
a1bfbb4f-b78b-4197-94e7-917f4e812043	\N	2015-01-16 08:51:06	field
bf73876b-8517-4123-a0ec-d862ba6e8797	\N	2015-01-16 08:51:06	field
94a72dbc-fa3d-4de0-b8ab-e9f5d6d577e6	\N	2019-08-05 15:36:33	field
95439019-2411-446b-823d-9904b2d188d1	\N	2019-08-05 15:17:15	field
d8a7431e-140d-4076-bf07-17fdfad6a14e	\N	2015-01-16 08:51:06	field
fa5ddfd5-4a3d-4cc1-8358-255497e16b8e	\N	2019-08-27 16:08:01	field
97f0c9f1-8dad-4fae-bab5-8f3826660091	\N	2019-08-27 16:08:01	field
99ac031c-7d72-4b08-bedd-37a71b594950	\N	2015-01-16 08:51:06	field
14534da0-9ead-4667-b4a4-993d33374fff	\N	2019-08-27 16:08:01	field
1677ca4f-e46f-449f-ae59-4952fb567e5e	\N	2015-01-16 08:51:06	field
e6a050cb-22fc-4a13-8646-5b60c25f2972	\N	2019-08-27 16:08:01	field
e58d33b7-17e5-4205-a191-4af292381019	\N	2019-08-27 16:08:01	field
0ef91b42-2fdf-4711-b9e6-a9a0cf389632	\N	2018-10-08 12:48:13	field
29175adc-271b-4691-ab7b-b40d11e8e408	\N	2019-03-15 16:53:12	field
2a083fcb-ceba-4daf-a6e3-405cd27f1620	\N	2019-03-15 16:53:12	field
95b191a7-a28e-463f-bb0f-e0d36fb40022	\N	2015-05-28 11:26:35	field
5971d5e7-3119-4c3e-b01d-0641aca79977	\N	2019-03-15 16:53:12	field
dfc5f28d-d47e-4007-869a-f2d5cfbc3d39	\N	2015-01-16 08:51:06	field
f00b3844-820d-4967-9f8e-0cce68d22b13	\N	2015-01-16 08:51:06	field
1aa4bbc6-d30e-4b43-8f13-d6e8f2a58a52	\N	2015-01-16 08:51:06	field
af75bdd6-21b9-451f-9fb9-abc763dbf4b1	\N	2019-03-15 16:53:12	field
3c63301e-1f8f-4f5f-b3a6-736a95d69d4d	\N	2019-03-15 16:53:12	field
c50906a6-dafb-4348-a185-a9334448813c	\N	2015-01-16 08:51:06	field
ba99667c-87be-44cd-82b6-4aa7bb157ac7	\N	2015-01-16 08:51:06	field
e633ab20-0aa1-4ed1-b052-82a711af61df	\N	2015-01-16 08:51:06	field
b0d65eee-b050-4fa2-bcf6-4016dc4e20af	\N	2015-01-16 08:51:06	field
855a2d72-f2f3-4169-8b04-ac5157c4380c	\N	2016-03-28 15:10:14.085	structure
d59ffe8d-7f46-4b68-a243-dbbd3be11f74	\N	2018-05-24 09:56:11	field
2b97316e-6801-4b61-9dfd-960fc2986380	\N	2018-05-24 09:56:11	field
ec8cc36f-6058-4ab5-9bfb-fc36ab011ee5	\N	2009-11-17 12:55:31	field
01f23a87-9859-4860-8368-f70a6ba9687f	\N	2009-11-17 12:55:31	field
cf5d08aa-7ff0-4fc8-a6ac-5a36e82cd741	\N	2011-12-15 17:19:14	field
c4628fad-9122-404a-8248-faaac4e6c29f	\N	2009-11-17 12:55:31	field
a0712c61-06ec-4019-a148-21d53fe05f92	\N	2009-11-17 12:55:31	field
8377586d-ac40-43b9-81ce-55b64f24433b	\N	2009-11-17 12:55:31	field
2f00a11d-f64c-4f8f-8126-238cc01fbf96	\N	2011-03-25 16:30:05	field
4e01f028-dbf8-41f6-8c3d-92c89e00ddbd	\N	2010-04-29 15:20:23	field
bca1a66b-4ab0-44aa-b73c-502390d4b4f1	\N	2010-04-20 10:49:20	field
04b1cdea-6c48-4a1b-bf47-6edfd5091246	\N	2010-04-20 10:46:18	field
5ee13991-970e-4a0b-b5e8-6547d7bb3bf2	\N	2010-04-29 15:21:31	field
f41dcc3c-36ce-4ea5-a621-23011936c418	\N	2010-04-29 15:22:24	field
02d02031-ef53-43f2-9845-6a2a85538072	\N	2010-06-17 14:54:11	field
4242af9d-2cc9-440f-a136-c92f1fe0e65a	\N	2011-07-07 14:21:07	field
f7f559fd-7100-45f5-b4e9-131a9d63984c	\N	2019-11-14 11:42:05	field
8f62657b-8915-489c-820e-12e8e272f1c1	\N	2018-05-24 09:56:11	field
897cf4a9-171a-4204-accb-c1b498c813fe	\N	2019-07-17 13:23:36	structure
4825beb5-4f85-4296-bccc-de6243713a98	\N	2019-07-17 13:23:36	field
a42bdb13-446d-4d8e-bf2c-630b0113a318	\N	2019-07-17 13:23:36	field
be12a0d9-d442-4224-ad78-e7cd14fa7e8b	\N	2019-07-17 13:23:36	field
449cf9d8-f5ce-47e6-bb26-eebe41a14bc8	\N	2019-07-17 13:23:36	field
87e33968-af6b-4f56-ae3b-db58bba7bacc	\N	2019-07-17 13:23:36	field
e9a4b604-08e6-4e54-af40-c46397da3142	\N	2019-07-17 13:23:36	field
1791b949-18bc-40ca-8c42-e2daa59d99cc	\N	2019-07-17 13:25:15	field
dce8e76b-038a-4c7b-811e-0b0541705a8d	\N	2019-07-17 13:25:15	field
5098c65f-2843-4fac-a656-e9fc1309c53c	\N	2019-07-17 13:25:15	field
17c86833-c9fd-4baf-bc99-582f66caee60	\N	2019-08-28 15:48:23	field
79870479-87c9-42f1-b32e-d3c11a5cf0a2	\N	2019-09-09 10:44:39	field
afb1b271-8177-4662-b3b6-82dcc3ef08d4	\N	2019-07-17 13:25:15	field
251f0fbe-a821-461b-beaf-a1d750f72be7	\N	2019-07-17 13:25:23	field
584c7d9f-15a6-4ac6-a1ea-50616f68cc94	\N	2019-07-17 13:25:44	field
0ee18c61-75fb-47b2-b7c5-73cdd72da45f	\N	2019-07-17 13:25:55	field
819668b0-72fb-475f-b1cb-0656eb53b622	\N	2019-07-17 13:26:15	field
f6d72f6a-358b-4ad1-810b-bfad491106fe	\N	2019-07-17 13:26:15	field
8303cdf7-9288-4171-9ab7-345bcece0745	\N	2019-09-09 10:48:46	field
aa52dcb1-6924-46fa-8236-ba90217a5e2f	\N	2019-09-10 14:30:22	field
3df8c272-c74f-4405-8b67-c8dbdf4bedb3	\N	2020-03-26 00:35:15	field
33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d	\N	2011-12-15 17:19:14.982	structure
b7bfe31d-60d3-4375-94fb-2a5304bbd67a	\N	2020-01-14 21:50:11	field
f0606fef-fbd1-40f9-9a0b-873399878166	\N	2020-01-14 21:50:11	field
9e194425-7cea-45b1-81b9-aa53b4f9641e	\N	2011-12-15 17:19:15	field
f07d5eeb-609c-414a-83c7-948fce643e99	\N	2011-12-15 17:19:15	field
468512c0-423e-4f1a-b94c-7cf8b064260a	\N	2011-12-15 17:19:15	field
f49faf40-ae06-48b4-8801-cf169c9d2eb7	\N	2011-12-15 17:19:15	field
3bceabd2-a59d-4ad7-86f2-b557bfc205bb	\N	2011-12-15 17:19:15	field
a0b83168-34e1-4c53-adcb-6996e6bae567	\N	2020-01-14 21:50:11	field
ae82aadc-d38c-433a-82f6-e2cdad9d7b03	\N	2020-01-14 21:50:11	field
c6960e09-8eb1-431e-8a5d-fa22d91cd6f1	\N	2011-12-15 17:19:15	field
b889dbf8-5e2c-4537-9f2b-024892cf2928	\N	2011-12-15 17:19:15	field
46c9ead3-f501-42ca-9ac6-289ef109809f	\N	2011-12-15 17:19:15	field
280f79fd-2c84-4840-8672-0651558974bd	\N	2011-12-15 17:19:15	field
2a3e91e4-fbbf-4876-8c5b-2233c1739b05	\N	2017-03-09 14:51:36.038	structure
ae8e673e-1c4e-4333-9cbe-d5dd73687d71	\N	2019-10-22 11:14:15	field
afcc3e3e-cb69-4e55-a131-a1f156ad06cf	\N	2019-10-22 11:14:15	field
49c5bd96-d70c-441c-9c5f-7ccaa8e7ff9a	\N	2010-02-25 12:57:09	field
9f5a97dc-703c-4721-9cce-29478671558b	\N	2010-02-23 22:05:55	field
5c6e0bff-cfeb-44c6-86e2-a0ba40e7b66c	\N	2010-02-23 22:06:24	field
d1835d27-32c3-4bb7-8bce-ac893fb36a0e	\N	2019-08-29 11:39:47	field
a1c63fad-5907-44e3-841d-e91c5cdcaa41	\N	2019-08-29 11:39:47	field
98e9924d-8847-4ceb-a2a7-19508c3c1106	\N	2010-04-23 10:26:58	field
7adb7ed2-4c15-4399-9675-c32f84ba8ff9	\N	2010-02-25 19:56:20	field
2d9bd5ac-ee66-4523-94a7-05897c609a98	\N	2010-07-19 09:55:18	field
773afa92-519e-4e13-b3eb-9eeb88f9dec7	\N	2019-07-11 16:39:37	field
61a1f907-a118-4e61-b8e5-7d23a4700681	\N	2019-07-10 12:06:40	field
b8fa0d70-4ea3-447f-a00c-9cc376077682	\N	2019-07-10 12:06:40	field
2a918837-0e1f-41b9-8fc0-e8fca2a1bff4	\N	2010-02-25 19:56:21	field
b7d91b8f-0acb-4da2-bc95-519cf7151eb2	\N	2019-07-10 12:06:40	field
28a791c8-67b9-4797-b036-bbad65a57ee7	\N	2010-02-25 19:56:21	field
413853a4-6a5b-4b84-a2bf-a78a54302bca	\N	2019-08-29 11:42:23	field
b8a1f389-ad7d-41d9-8169-815ae42ec557	\N	2019-08-29 11:42:23	field
2e680bab-5486-4db6-aec7-d0954392b1e0	\N	2019-09-13 14:58:31	field
4e129616-ee4f-4e7e-a978-a72dbdf1ae64	\N	2019-09-13 14:58:59	field
23cdb91f-e085-4177-ac41-83099d9027c0	\N	2019-09-13 14:58:59	field
33e793f0-f1dc-4986-847b-5b0a529b4373	\N	2010-02-25 19:56:21	field
95bdc5e0-0f70-471e-855f-ede8a157c375	\N	2019-09-13 14:58:59	field
1f414f9e-362b-4e10-a335-4a3bd11e0ff2	\N	2019-09-20 16:55:08	field
a92b093b-5d39-4ef7-aaf2-436a1884b491	\N	2019-07-10 11:58:56	field
6a470a84-f5d5-4e4d-b9d7-26d5386d9774	\N	2019-07-10 11:58:56	field
ed892f16-a88e-4cdc-b9c3-8324709f8a21	\N	2010-02-25 19:56:21	field
8d699885-867b-4b96-bff9-1198e96f8941	\N	2010-12-24 09:55:15	field
1f4b74e2-d00f-4245-840d-f84297438069	\N	2010-12-24 09:55:15	field
ea67f7b5-d7b4-4f7c-ae1a-5c008f3a8a16	\N	2010-12-24 09:55:15	field
314c6664-d8be-452b-acca-d62d908b4a34	\N	2010-12-24 09:55:15	field
c46e28fd-38e9-46d2-ab04-168b18cbde23	\N	2010-12-24 09:55:15	field
f231c8a7-9606-4823-8185-6e2172fd5506	\N	2010-12-24 09:55:15	field
5074b1c3-0bc3-495f-be95-72c82d749a67	\N	2010-12-24 09:55:15	field
b48eb11e-8de0-417d-a768-46fa4d0e0b5c	\N	2010-12-24 09:55:15	field
1da87215-92d1-499c-aeda-517d54114ead	\N	2010-12-24 09:55:15	field
74715ca5-6f1c-4580-b511-f91dbe5ad703	\N	2010-12-24 09:55:15	field
a8ee0bef-3f5b-4572-9a24-c4d0112548c4	\N	2010-12-24 09:55:15	field
40f1dd0a-d4dd-4ce7-abef-0bc1ce711bb4	\N	2010-12-24 09:55:15	field
5a3bcf8b-0939-4996-b8c8-57bc76ad5fef	\N	2010-12-24 09:55:15	field
cf46e80e-7b1f-40b1-b9c7-fb837af60d38	\N	2010-12-24 09:55:15	field
f6259cc9-5d78-453e-8167-efd7b72b2e96	\N	2014-08-05 11:18:23.938	structure
0c3418eb-4c27-4d71-937d-bf231399312a	dotcms.org.1	2020-02-04 10:44:16.733	contentlet
dbdec5e2-c02b-4cfb-83a9-4a4c4f3b2eb0	system	2009-11-17 12:55:33	contentlet
45d04c50-df12-4f29-93dd-4b6721870f4e		2018-12-17 15:02:00.29	template
06bc889b-d859-4d90-87a8-9eaa41cc6295		2019-04-16 12:52:48.766	template
8a780107-a9fe-4871-ab31-32c7d920518b		2019-07-26 15:06:54.484	template
be5383eb-fa12-4884-bdc8-7c2cb516c5b5		2019-07-26 15:06:54.484	template
cfda9246-cce3-4313-8cc3-2080d1935cf9		2020-01-10 15:21:42.481	template
a0867428-0bdb-4191-af2f-4c19637ef40b		2019-09-09 08:55:26.776	template
4def88a9-de8c-4f18-a9ca-f75e9cc516f5		2019-10-08 12:30:02.761	template
ae0ea552-4a97-483b-b456-1c304491a5d5		2019-10-21 15:52:05.011	template
8ab7a996-318d-48c1-baf4-62d6f0ce134a		2019-07-01 16:43:27.321	template
2162bbbb-ec25-47ff-8e05-f70f6125981d		2019-09-12 10:33:17.037	template
1b8e9931-cbea-4ee7-b2b0-2c5911b4e575		2019-07-26 11:45:14.104	template
f9455e7a-bd1a-4cb7-9556-b7ede4f93fc3		2018-10-30 13:34:43.9	template
a7d001e5-d6e8-4f82-9d08-ea7487e2689f		2019-10-04 16:49:49.516	template
d1113914-c2e4-4067-8c3a-68981d786a75		2019-10-04 11:33:04.565	template
0856a795-cba1-488a-ba13-f10f2983a42d		2019-08-28 11:48:15.411	template
fa0a5930-c733-4a8f-91bf-d4bad9d1ea9e		2019-09-20 11:35:27.856	template
a2ed6aec-ecd7-4390-a4d4-d3047424fc84		2019-04-11 12:14:30.951	template
1d83162a-edaf-412b-b004-295992eb5caa		2019-04-11 12:14:30.951	template
b2440bc7-f3d0-4bd8-8fa5-28952fd37f62		2019-08-09 17:08:29.789	template
54b4cf8d-0538-4862-a392-e544bb865c38		2019-07-10 10:54:26.312	template
59e3bb7c-abf0-41ea-9b22-000c862b8d13		2019-07-30 19:34:58.079	template
543b5efa-eb96-4868-8bad-1d96e99ab93f		2019-07-29 09:30:03.686	template
9164f879-b4bb-46de-a306-4cdd7952253d		2019-07-25 14:42:31.538	template
b7046ed2-ccf0-45c6-8819-d4c3994ce765		2018-11-01 14:57:23.885	template
98d027b1-189d-41e2-adba-9f873b593e86		2019-07-16 17:26:49.674	template
8b823726-37c0-487e-a0d8-7e10ea57ea94		2018-11-28 12:49:52.897	template
80d27245-8e05-42b4-955b-c48811b8b24e		2019-07-09 16:47:48.252	template
fc19f48f-0098-47a0-b0ad-040cf25c7270		2019-04-18 10:17:26.917	template
c93c3500-2a0f-4cd6-b5c6-0490b1e014d1		2019-07-01 18:32:06.269	template
c3973631-3038-4bdb-b27e-25b8fd82cf24		2019-05-22 12:27:00.435	template
50938cdd-6855-4761-9d67-86557093a682		2019-04-11 12:16:24.712	template
704bb3b3-10d7-45d0-a36a-6029838bda85		2018-11-02 13:47:50.311	template
9962d47f-0f4a-436b-92d8-6045efd60396		2019-04-16 18:47:59.41	template
cfca3943-5f2c-4caf-9a6e-874c5db06f3f		2019-06-03 13:13:20.804	template
289410c6-9b76-4b48-94c6-f8d04bccc3df		2019-05-22 14:34:41.911	template
0f73fef5-7269-41f3-9438-9830a457b6a0		2019-05-22 12:27:00.435	template
92fb0fee-5aa7-409c-87ef-63cb3f3c70f4		2019-04-11 12:16:24.712	template
f4240c47-913e-4c1a-8e54-e80eb1e7961d		2019-05-17 08:42:27.715	template
10013c6a-ec0a-4b54-b406-c75d1c3cd2f3		2019-05-17 08:42:10.426	template
2d586171-ca0e-439d-8cec-0203cbecac07		2019-04-18 10:17:26.917	template
3048660e-c036-47b8-9bde-6ef96ff609a7		2019-04-17 07:24:24.392	template
76fdb150-ceae-4033-8f39-bb97a5332fc5		2019-04-17 07:18:47.514	template
30ced9f0-be4c-4a3e-9dfc-00dd782ec9d1		2019-04-16 18:09:27.681	template
86b9c834-bb74-4e19-8743-cf23e166f711		2019-04-16 18:10:19.419	template
969ca173-fbdd-4e26-8f2e-1d9ba8521bdc		2019-04-16 12:51:47.192	template
0546d6b9-63bd-466e-bc05-c467fd7e2d61		2019-04-16 18:47:59.41	template
cc5ef9c6-737e-41a6-992f-8cb397248266		2018-11-27 14:42:07.195	template
97aad934-5d1e-4132-a61c-46f33d1b318d		2018-10-31 16:55:52.471	template
0702913b-f954-469f-a05f-5d3fc616daf2		2019-04-15 12:14:37.435	template
abe89660-1b0b-48c9-9023-826267b07876		2019-04-15 12:14:37.435	template
6c764cc6-4e3d-4eac-96cf-a3f403c93e8c		2019-04-11 12:24:40.136	template
0934f429-d611-4c35-b13c-8c49ac2064e6		2019-04-11 14:10:09.831	template
5c331799-df72-4780-bfa1-56425b0854fe		2018-11-01 13:15:14.841	template
45c44f30-c90a-4deb-9fa7-ef270aa09c69		2018-11-05 09:40:49.246	template
757334b2-1690-4b68-8686-1ab99dbc7c17		2018-11-02 13:41:46.291	template
e1785c86-0096-4e1e-a799-a2cb273c9a29		2018-10-31 09:53:47.406	template
398300f4-1394-4514-9ad4-8809680b92a4		2018-10-05 09:10:45.749	template
ed0c3959-bfb2-4a8e-927a-17c4d03c9261		2018-11-02 11:57:16.655	template
786c0357-ea7e-4c9e-8468-d045424bbab5		2018-10-25 09:36:22.434	template
5521a1d4-ccf4-431e-a62d-57c3857ba9df		2018-09-14 17:46:43.279	template
78bde330-97af-49f5-a62a-46a624f4a6b1		2018-09-25 12:19:10.25	template
fe871bb5-be92-48d1-90d6-83d299444c77		2018-09-25 10:44:53.058	template
5b12f27b-6a9b-4179-9fb8-7f6032303877		2018-09-24 22:58:28.61	template
2b58d456-e891-4433-b9c2-f0086669ae0a		2018-09-24 20:40:03.471	template
264b9596-95dc-41e2-a3ab-ce8a94542055		2018-09-24 11:39:20.733	template
f0216d57-8d4c-4863-a3e8-9ef3ff168f1f		2018-09-24 09:04:31.95	template
f2b7c8d8-a7c1-4334-9c0d-01ea70822baf		2018-09-21 12:02:21.17	template
354e2ec6-aba0-4c70-be8b-4136a44e04dc		2018-09-18 13:24:50.645	template
2e68de1c-51d9-4cb1-86e1-bdfb87a28239		2018-09-18 12:22:29.392	template
a090b2b0-0753-4771-934e-660b0368113c		2018-07-24 15:09:05.326	template
f5879d20-abff-479d-aaa4-b417a3725998		2018-07-24 15:09:05.326	template
adba605c-4370-4db3-962e-b91ec4604e99		2018-07-18 09:35:56.684	template
367a8fa6-327d-4858-b26c-e095036dee88		2018-06-13 16:26:35.705	template
84d3cfd1-b476-4bd9-a775-7c0c421c3937		2018-06-13 15:52:13.653	template
ab656a52-cd55-450b-818f-a33ac3996297		2018-06-13 11:47:01.177	template
a9b894fc-48dc-485b-b2d9-587956515e4c		2018-04-06 13:11:20.204	template
4c7ce396-0685-4b66-bcfc-6561dd7dad33		2018-03-05 09:50:08.317	template
0d0dc435-998d-439e-aad6-10cd7743f528	\N	2019-11-05 14:24:59.288	template
574d6ad5-a950-432c-997c-7c1a35eefed3	\N	2019-08-28 10:35:16.601	template
316a7de7-7b0e-4322-b925-09f177afd0c2	\N	2019-08-28 15:39:10.494	template
9d11b327-9bf5-4d42-92bd-7894d56ed218	\N	2019-10-04 14:46:34.641	template
75bfe924-3a59-4cff-aa59-2b9b00a20efe	\N	2019-10-22 17:56:32.715	template
3a79250a-cd9c-455f-b41c-64a18088cd93	\N	2019-10-22 17:59:26.313	template
\.


--
-- Data for Name: language; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.language (id, language_code, country_code, language, country) FROM stdin;
1	en	US	English	United States
2	es	ES	Espanol	Espana
\.


--
-- Data for Name: layouts_cms_roles; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.layouts_cms_roles (id, layout_id, role_id) FROM stdin;
0074a8b8-e79f-454e-b876-b624725e5702	34885ddb-3537-4a79-a02c-0550c5087d5c	892ab105-f212-407f-8fb4-58ec59310a5e
0e690462-4f37-4498-a95d-49b2bf7b1630	71b8a1ca-37b6-4b6e-a43b-c7482f28db6c	e36988eb-f206-4fd3-a06c-6a746d30a772
0e8280f6-dbb0-40cc-9e6b-9406ab9f64f3	71b8a1ca-37b6-4b6e-a43b-c7482f28db6c	02ae46fa-cb67-4ed8-82d5-f1f9a5e1d744
0f285dd4-bc9e-4760-9bc7-02e581e7529a	0c032208-7514-457e-a9e8-26b9e368db64	892ab105-f212-407f-8fb4-58ec59310a5e
25010dc1-1209-427a-8108-5555b2a14d9c	34885ddb-3537-4a79-a02c-0550c5087d5c	db0d2bca-5da5-4c18-b5d7-87f02ba58eb6
27129375-8565-474e-bd57-3092edd556b6	56fedb43-dbbf-4ce2-8b77-41fb73bad015	892ab105-f212-407f-8fb4-58ec59310a5e
27194d1e-b803-40c4-8917-5d96bd6d1862	71b8a1ca-37b6-4b6e-a43b-c7482f28db6c	1cddb9f9-2443-49f8-a51d-f24f1d7622ac
52188fdc-ed3a-4dd4-8819-554179cc8384	34885ddb-3537-4a79-a02c-0550c5087d5c	02ae46fa-cb67-4ed8-82d5-f1f9a5e1d744
5225f561-7bc0-4218-a96e-8c5151333692	b7ab5d3c-5ee0-4195-a17e-8f5579d718dd	892ab105-f212-407f-8fb4-58ec59310a5e
6a76ed1e-58e7-45f8-ad88-0bb38db1e186	1a87b81c-e7ec-4e5b-9218-b55790353f09	892ab105-f212-407f-8fb4-58ec59310a5e
73484d00-b8bb-4cd3-8f50-0c670ee5bcd5	b7ab5d3c-5ee0-4195-a17e-8f5579d718dd	02ae46fa-cb67-4ed8-82d5-f1f9a5e1d744
8d600bce-7b38-490a-80ce-b9402a0cdcf5	56fedb43-dbbf-4ce2-8b77-41fb73bad015	02ae46fa-cb67-4ed8-82d5-f1f9a5e1d744
b4500b68-e5a2-4b10-9abc-a32ba2e06c05	71b8a1ca-37b6-4b6e-a43b-c7482f28db6c	892ab105-f212-407f-8fb4-58ec59310a5e
b6d01116-51da-442f-8d63-3649d8efcfbf	89594b95-1354-4a63-8867-c922880107df	892ab105-f212-407f-8fb4-58ec59310a5e
ca7c4a40-79de-4348-8dab-d7ceeb5de4e8	71b8a1ca-37b6-4b6e-a43b-c7482f28db6c	db0d2bca-5da5-4c18-b5d7-87f02ba58eb6
de298a86-b012-4bc5-a514-02f5ea5256a5	34885ddb-3537-4a79-a02c-0550c5087d5c	e36988eb-f206-4fd3-a06c-6a746d30a772
ffffd3f5-9eb1-4498-95db-4407ba7ab6ce	aa91172e-0fa6-482e-9a8b-1c202c7fca0e	892ab105-f212-407f-8fb4-58ec59310a5e
\.


--
-- Data for Name: link_version_info; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.link_version_info (identifier, working_inode, live_inode, deleted, locked_by, locked_on, version_ts) FROM stdin;
\.


--
-- Data for Name: links; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.links (inode, show_on_menu, title, mod_date, mod_user, sort_order, friendly_name, identifier, protocal, url, target, internal_link_identifier, link_type, link_code) FROM stdin;
\.


--
-- Data for Name: log_mapper; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.log_mapper (enabled, log_name, description) FROM stdin;
1	dotcms-userActivity.log	Log Users action on pages, structures, documents.
1	dotcms-security.log	Log users login activity into dotCMS.
1	dotcms-adminaudit.log	Log Admin activity on dotCMS.
1	dotcms-pushpublish.log	Log Push Publishing activity on dotCMS.
1	visitor-v3.log	Log Visitor Filter activity on dotCMS.
\.


--
-- Data for Name: mailing_list; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.mailing_list (inode, title, public_list, user_id) FROM stdin;
\.


--
-- Data for Name: multi_tree; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.multi_tree (child, parent1, parent2, relation_type, tree_order, personalization) FROM stdin;
\.


--
-- Data for Name: notification; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.notification (group_id, user_id, message, notification_type, notification_level, time_sent, was_read) FROM stdin;
d06c7415-7b1a-4418-81ba-205f4a44ce23	036fd43a-6d98-46e0-b22e-bae02cb86f0c	{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}}	GENERIC	INFO	2020-03-26 00:54:38.521	f
d06c7415-7b1a-4418-81ba-205f4a44ce23	system	{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}}	GENERIC	INFO	2020-03-26 00:54:38.521	f
d06c7415-7b1a-4418-81ba-205f4a44ce23	86fe5be1-4624-4595-bf2d-af8d559414b1	{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}}	GENERIC	INFO	2020-03-26 00:54:38.521	f
d06c7415-7b1a-4418-81ba-205f4a44ce23	dotcms.org.2808	{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}}	GENERIC	INFO	2020-03-26 00:54:38.521	f
d06c7415-7b1a-4418-81ba-205f4a44ce23	user-ddb808e6-4f68-4f7a-96d0-81277a66953f	{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}}	GENERIC	INFO	2020-03-26 00:54:38.521	f
ebfa87e2-66ef-4d8d-8d9e-5fcfed2ecbc3	036fd43a-6d98-46e0-b22e-bae02cb86f0c	{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}}	GENERIC	INFO	2020-03-26 00:54:42.003	f
ebfa87e2-66ef-4d8d-8d9e-5fcfed2ecbc3	system	{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}}	GENERIC	INFO	2020-03-26 00:54:42.003	f
ebfa87e2-66ef-4d8d-8d9e-5fcfed2ecbc3	86fe5be1-4624-4595-bf2d-af8d559414b1	{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}}	GENERIC	INFO	2020-03-26 00:54:42.003	f
ebfa87e2-66ef-4d8d-8d9e-5fcfed2ecbc3	dotcms.org.2808	{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}}	GENERIC	INFO	2020-03-26 00:54:42.003	f
ebfa87e2-66ef-4d8d-8d9e-5fcfed2ecbc3	user-ddb808e6-4f68-4f7a-96d0-81277a66953f	{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}}	GENERIC	INFO	2020-03-26 00:54:42.003	f
3e84d1ae-e007-438c-9a2f-551e8e654b06	036fd43a-6d98-46e0-b22e-bae02cb86f0c	{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}}	GENERIC	INFO	2020-03-26 00:54:45.506	f
3e84d1ae-e007-438c-9a2f-551e8e654b06	system	{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}}	GENERIC	INFO	2020-03-26 00:54:45.506	f
3e84d1ae-e007-438c-9a2f-551e8e654b06	86fe5be1-4624-4595-bf2d-af8d559414b1	{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}}	GENERIC	INFO	2020-03-26 00:54:45.506	f
3e84d1ae-e007-438c-9a2f-551e8e654b06	dotcms.org.2808	{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}}	GENERIC	INFO	2020-03-26 00:54:45.506	f
3e84d1ae-e007-438c-9a2f-551e8e654b06	user-ddb808e6-4f68-4f7a-96d0-81277a66953f	{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}}	GENERIC	INFO	2020-03-26 00:54:45.506	f
750c84a1-f050-4262-8a2e-abb213baf367	036fd43a-6d98-46e0-b22e-bae02cb86f0c	{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}}	GENERIC	INFO	2020-03-26 00:54:49.008	f
750c84a1-f050-4262-8a2e-abb213baf367	system	{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}}	GENERIC	INFO	2020-03-26 00:54:49.008	f
750c84a1-f050-4262-8a2e-abb213baf367	86fe5be1-4624-4595-bf2d-af8d559414b1	{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}}	GENERIC	INFO	2020-03-26 00:54:49.008	f
750c84a1-f050-4262-8a2e-abb213baf367	dotcms.org.2808	{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}}	GENERIC	INFO	2020-03-26 00:54:49.008	f
750c84a1-f050-4262-8a2e-abb213baf367	user-ddb808e6-4f68-4f7a-96d0-81277a66953f	{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}}	GENERIC	INFO	2020-03-26 00:54:49.008	f
ff893cdc-a013-4f4e-8562-7a8dc2e22dbd	036fd43a-6d98-46e0-b22e-bae02cb86f0c	{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}}	GENERIC	INFO	2020-03-26 00:54:49.581	f
ff893cdc-a013-4f4e-8562-7a8dc2e22dbd	system	{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}}	GENERIC	INFO	2020-03-26 00:54:49.581	f
ff893cdc-a013-4f4e-8562-7a8dc2e22dbd	86fe5be1-4624-4595-bf2d-af8d559414b1	{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}}	GENERIC	INFO	2020-03-26 00:54:49.581	f
ff893cdc-a013-4f4e-8562-7a8dc2e22dbd	dotcms.org.2808	{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}}	GENERIC	INFO	2020-03-26 00:54:49.581	f
ff893cdc-a013-4f4e-8562-7a8dc2e22dbd	user-ddb808e6-4f68-4f7a-96d0-81277a66953f	{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}}	GENERIC	INFO	2020-03-26 00:54:49.581	f
50a5c0e2-d8ee-412d-a6c5-cd4e9f4d03ca	system	{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}}	GENERIC	INFO	2020-03-26 01:06:30.08	f
50a5c0e2-d8ee-412d-a6c5-cd4e9f4d03ca	dotcms.org.2808	{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}}	GENERIC	INFO	2020-03-26 01:06:30.08	f
749adecf-7882-4fe0-b60c-cfe1e4670d2c	system	{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}}	GENERIC	INFO	2020-03-26 01:06:33.581	f
749adecf-7882-4fe0-b60c-cfe1e4670d2c	dotcms.org.2808	{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}}	GENERIC	INFO	2020-03-26 01:06:33.581	f
8f47ce63-83b6-4b42-925c-d4cfb41b858c	system	{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}}	GENERIC	INFO	2020-03-26 01:06:37.083	f
8f47ce63-83b6-4b42-925c-d4cfb41b858c	dotcms.org.2808	{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}}	GENERIC	INFO	2020-03-26 01:06:37.083	f
249ad4c9-038c-4b93-ac47-f5a2d3a37d38	system	{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}}	GENERIC	INFO	2020-03-26 01:06:40.585	f
249ad4c9-038c-4b93-ac47-f5a2d3a37d38	dotcms.org.2808	{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}}	GENERIC	INFO	2020-03-26 01:06:40.585	f
8a848cd9-c261-4ae6-bcee-58c018cd0492	system	{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}}	GENERIC	INFO	2020-03-26 01:06:41.095	f
8a848cd9-c261-4ae6-bcee-58c018cd0492	dotcms.org.2808	{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}}	GENERIC	INFO	2020-03-26 01:06:41.095	f
2d1e7408-b8e4-4e27-a263-701028912559	system	{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}}	GENERIC	INFO	2020-03-26 01:10:17.104	f
2d1e7408-b8e4-4e27-a263-701028912559	dotcms.org.2808	{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}}	GENERIC	INFO	2020-03-26 01:10:17.104	f
2f215fec-3128-47fa-96f5-daba65ebf779	system	{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}}	GENERIC	INFO	2020-03-26 01:10:20.605	f
2f215fec-3128-47fa-96f5-daba65ebf779	dotcms.org.2808	{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}}	GENERIC	INFO	2020-03-26 01:10:20.605	f
31a5bd0d-d13b-463b-9145-20d30562cf7e	system	{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}}	GENERIC	INFO	2020-03-26 01:10:24.107	f
31a5bd0d-d13b-463b-9145-20d30562cf7e	dotcms.org.2808	{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}}	GENERIC	INFO	2020-03-26 01:10:24.107	f
017f57cd-c634-490e-a95b-704349251d52	system	{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}}	GENERIC	INFO	2020-03-26 01:10:27.611	f
017f57cd-c634-490e-a95b-704349251d52	dotcms.org.2808	{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}}	GENERIC	INFO	2020-03-26 01:10:27.611	f
af31cf71-fb72-4d54-bff4-dfc6f386563c	system	{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}}	GENERIC	INFO	2020-03-26 01:10:28.179	f
af31cf71-fb72-4d54-bff4-dfc6f386563c	dotcms.org.2808	{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}}	GENERIC	INFO	2020-03-26 01:10:28.179	f
\.


--
-- Data for Name: passwordtracker; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.passwordtracker (passwordtrackerid, userid, createdate, password_) FROM stdin;
\.


--
-- Data for Name: permission; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.permission (id, permission_type, inode_id, roleid, permission) FROM stdin;
2148	individual	1231	892ab105-f212-407f-8fb4-58ec59310a5e	7
2407	individual	1360	892ab105-f212-407f-8fb4-58ec59310a5e	31
2408	individual	1360	654b0931-1027-41f7-ad4d-173115ed8ec1	1
2419	individual	1061	892ab105-f212-407f-8fb4-58ec59310a5e	31
2422	individual	1061	654b0931-1027-41f7-ad4d-173115ed8ec1	1
2423	individual	1370	892ab105-f212-407f-8fb4-58ec59310a5e	31
2424	individual	1370	654b0931-1027-41f7-ad4d-173115ed8ec1	1
2472	individual	1404	892ab105-f212-407f-8fb4-58ec59310a5e	31
2473	individual	1404	654b0931-1027-41f7-ad4d-173115ed8ec1	1
2954	individual	1631	e828467a-f128-4d3c-8873-d967631bf130	7
2957	individual	1631	dbd027dc-9587-422f-a8be-c7c1ddd08691	7
2963	individual	1631	654b0931-1027-41f7-ad4d-173115ed8ec1	1
2964	individual	1631	892ab105-f212-407f-8fb4-58ec59310a5e	31
3271	individual	839	892ab105-f212-407f-8fb4-58ec59310a5e	7
3272	individual	839	654b0931-1027-41f7-ad4d-173115ed8ec1	1
3273	individual	839	6b1fa42f-8729-4625-80d1-17e4ef691ce7	1
3274	individual	839	999cd6bf-5cef-4729-8543-696086143884	1
3301	individual	827	892ab105-f212-407f-8fb4-58ec59310a5e	7
3302	individual	827	654b0931-1027-41f7-ad4d-173115ed8ec1	1
3303	individual	827	6b1fa42f-8729-4625-80d1-17e4ef691ce7	1
3304	individual	827	999cd6bf-5cef-4729-8543-696086143884	1
3457	individual	1818	dbd027dc-9587-422f-a8be-c7c1ddd08691	7
3460	individual	1818	654b0931-1027-41f7-ad4d-173115ed8ec1	1
3473	individual	1827	892ab105-f212-407f-8fb4-58ec59310a5e	7
3476	individual	1827	654b0931-1027-41f7-ad4d-173115ed8ec1	1
3477	individual	1829	892ab105-f212-407f-8fb4-58ec59310a5e	7
3480	individual	1829	654b0931-1027-41f7-ad4d-173115ed8ec1	1
3493	individual	1835	892ab105-f212-407f-8fb4-58ec59310a5e	7
4102	individual	1626	892ab105-f212-407f-8fb4-58ec59310a5e	7
4103	individual	1626	654b0931-1027-41f7-ad4d-173115ed8ec1	1
4110	individual	1942	892ab105-f212-407f-8fb4-58ec59310a5e	7
4111	individual	1942	654b0931-1027-41f7-ad4d-173115ed8ec1	1
4630	individual	2061	892ab105-f212-407f-8fb4-58ec59310a5e	7
4633	individual	2061	654b0931-1027-41f7-ad4d-173115ed8ec1	1
4634	individual	2064	892ab105-f212-407f-8fb4-58ec59310a5e	7
4637	individual	2066	892ab105-f212-407f-8fb4-58ec59310a5e	7
4640	individual	2068	892ab105-f212-407f-8fb4-58ec59310a5e	7
4665	individual	2116	892ab105-f212-407f-8fb4-58ec59310a5e	7
4668	individual	2116	654b0931-1027-41f7-ad4d-173115ed8ec1	1
4675	individual	2131	892ab105-f212-407f-8fb4-58ec59310a5e	7
4684	individual	2131	dbd027dc-9587-422f-a8be-c7c1ddd08691	7
4690	individual	2131	a2d88e69-d575-45ec-9b52-0dc3a51468ed	7
4696	individual	2131	f10eab25-ab4b-444f-b1b5-15a1a5948024	7
4699	individual	2131	654b0931-1027-41f7-ad4d-173115ed8ec1	1
4700	individual	2137	892ab105-f212-407f-8fb4-58ec59310a5e	7
4709	individual	2137	dbd027dc-9587-422f-a8be-c7c1ddd08691	7
4715	individual	2137	a2d88e69-d575-45ec-9b52-0dc3a51468ed	7
4721	individual	2137	f10eab25-ab4b-444f-b1b5-15a1a5948024	7
4724	individual	2137	654b0931-1027-41f7-ad4d-173115ed8ec1	1
4725	individual	2140	892ab105-f212-407f-8fb4-58ec59310a5e	7
4734	individual	2140	dbd027dc-9587-422f-a8be-c7c1ddd08691	7
4740	individual	2140	a2d88e69-d575-45ec-9b52-0dc3a51468ed	7
4746	individual	2140	f10eab25-ab4b-444f-b1b5-15a1a5948024	7
4749	individual	2140	654b0931-1027-41f7-ad4d-173115ed8ec1	1
4750	individual	2143	892ab105-f212-407f-8fb4-58ec59310a5e	7
4759	individual	2143	dbd027dc-9587-422f-a8be-c7c1ddd08691	7
4765	individual	2143	a2d88e69-d575-45ec-9b52-0dc3a51468ed	7
4771	individual	2143	f10eab25-ab4b-444f-b1b5-15a1a5948024	7
4774	individual	2143	654b0931-1027-41f7-ad4d-173115ed8ec1	1
4775	individual	2145	892ab105-f212-407f-8fb4-58ec59310a5e	7
4784	individual	2145	dbd027dc-9587-422f-a8be-c7c1ddd08691	7
4790	individual	2145	a2d88e69-d575-45ec-9b52-0dc3a51468ed	7
4796	individual	2145	f10eab25-ab4b-444f-b1b5-15a1a5948024	7
4799	individual	2145	654b0931-1027-41f7-ad4d-173115ed8ec1	1
4800	individual	2147	892ab105-f212-407f-8fb4-58ec59310a5e	7
4809	individual	2147	dbd027dc-9587-422f-a8be-c7c1ddd08691	7
4815	individual	2147	a2d88e69-d575-45ec-9b52-0dc3a51468ed	7
4821	individual	2147	f10eab25-ab4b-444f-b1b5-15a1a5948024	7
4824	individual	2147	654b0931-1027-41f7-ad4d-173115ed8ec1	1
4825	individual	2149	892ab105-f212-407f-8fb4-58ec59310a5e	7
4834	individual	2149	dbd027dc-9587-422f-a8be-c7c1ddd08691	7
4840	individual	2149	a2d88e69-d575-45ec-9b52-0dc3a51468ed	7
4846	individual	2149	f10eab25-ab4b-444f-b1b5-15a1a5948024	7
4849	individual	2149	654b0931-1027-41f7-ad4d-173115ed8ec1	1
4850	individual	2151	892ab105-f212-407f-8fb4-58ec59310a5e	7
4859	individual	2151	dbd027dc-9587-422f-a8be-c7c1ddd08691	7
4865	individual	2151	a2d88e69-d575-45ec-9b52-0dc3a51468ed	7
4871	individual	2151	f10eab25-ab4b-444f-b1b5-15a1a5948024	7
4874	individual	2151	654b0931-1027-41f7-ad4d-173115ed8ec1	1
4875	individual	2153	892ab105-f212-407f-8fb4-58ec59310a5e	7
4884	individual	2153	dbd027dc-9587-422f-a8be-c7c1ddd08691	7
4890	individual	2153	a2d88e69-d575-45ec-9b52-0dc3a51468ed	7
4896	individual	2153	f10eab25-ab4b-444f-b1b5-15a1a5948024	7
4899	individual	2153	654b0931-1027-41f7-ad4d-173115ed8ec1	1
4900	individual	2155	892ab105-f212-407f-8fb4-58ec59310a5e	7
4909	individual	2155	dbd027dc-9587-422f-a8be-c7c1ddd08691	7
4915	individual	2155	a2d88e69-d575-45ec-9b52-0dc3a51468ed	7
4921	individual	2155	f10eab25-ab4b-444f-b1b5-15a1a5948024	7
4924	individual	2155	654b0931-1027-41f7-ad4d-173115ed8ec1	1
4925	individual	2157	892ab105-f212-407f-8fb4-58ec59310a5e	7
4934	individual	2157	dbd027dc-9587-422f-a8be-c7c1ddd08691	7
4946	individual	2157	f10eab25-ab4b-444f-b1b5-15a1a5948024	7
4949	individual	2157	654b0931-1027-41f7-ad4d-173115ed8ec1	1
4950	individual	2159	892ab105-f212-407f-8fb4-58ec59310a5e	7
4959	individual	2159	dbd027dc-9587-422f-a8be-c7c1ddd08691	7
4965	individual	2159	a2d88e69-d575-45ec-9b52-0dc3a51468ed	7
4971	individual	2159	f10eab25-ab4b-444f-b1b5-15a1a5948024	7
4974	individual	2159	654b0931-1027-41f7-ad4d-173115ed8ec1	1
4975	individual	2161	892ab105-f212-407f-8fb4-58ec59310a5e	7
4984	individual	2161	dbd027dc-9587-422f-a8be-c7c1ddd08691	7
4990	individual	2161	a2d88e69-d575-45ec-9b52-0dc3a51468ed	7
4996	individual	2161	f10eab25-ab4b-444f-b1b5-15a1a5948024	7
4999	individual	2161	654b0931-1027-41f7-ad4d-173115ed8ec1	1
5000	individual	2163	892ab105-f212-407f-8fb4-58ec59310a5e	7
5009	individual	2163	dbd027dc-9587-422f-a8be-c7c1ddd08691	7
5015	individual	2163	a2d88e69-d575-45ec-9b52-0dc3a51468ed	7
5021	individual	2163	f10eab25-ab4b-444f-b1b5-15a1a5948024	7
5024	individual	2163	654b0931-1027-41f7-ad4d-173115ed8ec1	1
5025	individual	2165	892ab105-f212-407f-8fb4-58ec59310a5e	7
5034	individual	2165	dbd027dc-9587-422f-a8be-c7c1ddd08691	7
5040	individual	2165	a2d88e69-d575-45ec-9b52-0dc3a51468ed	7
5046	individual	2165	f10eab25-ab4b-444f-b1b5-15a1a5948024	7
5049	individual	2165	654b0931-1027-41f7-ad4d-173115ed8ec1	1
5050	individual	2167	892ab105-f212-407f-8fb4-58ec59310a5e	7
5059	individual	2167	dbd027dc-9587-422f-a8be-c7c1ddd08691	7
5065	individual	2167	a2d88e69-d575-45ec-9b52-0dc3a51468ed	7
5071	individual	2167	f10eab25-ab4b-444f-b1b5-15a1a5948024	7
5074	individual	2167	654b0931-1027-41f7-ad4d-173115ed8ec1	1
5075	individual	2169	892ab105-f212-407f-8fb4-58ec59310a5e	7
5084	individual	2169	dbd027dc-9587-422f-a8be-c7c1ddd08691	7
5090	individual	2169	a2d88e69-d575-45ec-9b52-0dc3a51468ed	7
5096	individual	2169	f10eab25-ab4b-444f-b1b5-15a1a5948024	7
5099	individual	2169	654b0931-1027-41f7-ad4d-173115ed8ec1	1
5100	individual	2175	892ab105-f212-407f-8fb4-58ec59310a5e	7
5109	individual	2175	dbd027dc-9587-422f-a8be-c7c1ddd08691	7
5115	individual	2175	a2d88e69-d575-45ec-9b52-0dc3a51468ed	7
5121	individual	2175	f10eab25-ab4b-444f-b1b5-15a1a5948024	7
5124	individual	2175	654b0931-1027-41f7-ad4d-173115ed8ec1	1
5125	individual	2178	892ab105-f212-407f-8fb4-58ec59310a5e	7
5128	individual	2178	654b0931-1027-41f7-ad4d-173115ed8ec1	1
5131	individual	2178	f10eab25-ab4b-444f-b1b5-15a1a5948024	7
5137	individual	2178	a2d88e69-d575-45ec-9b52-0dc3a51468ed	7
5143	individual	2178	dbd027dc-9587-422f-a8be-c7c1ddd08691	7
5150	individual	2180	892ab105-f212-407f-8fb4-58ec59310a5e	7
5153	individual	2180	654b0931-1027-41f7-ad4d-173115ed8ec1	1
5156	individual	2180	f10eab25-ab4b-444f-b1b5-15a1a5948024	7
5162	individual	2180	a2d88e69-d575-45ec-9b52-0dc3a51468ed	7
5168	individual	2180	dbd027dc-9587-422f-a8be-c7c1ddd08691	7
5175	individual	2187	892ab105-f212-407f-8fb4-58ec59310a5e	7
5184	individual	2187	dbd027dc-9587-422f-a8be-c7c1ddd08691	7
5190	individual	2187	a2d88e69-d575-45ec-9b52-0dc3a51468ed	7
5196	individual	2187	f10eab25-ab4b-444f-b1b5-15a1a5948024	7
5199	individual	2187	654b0931-1027-41f7-ad4d-173115ed8ec1	1
5200	individual	2190	892ab105-f212-407f-8fb4-58ec59310a5e	7
5203	individual	2190	654b0931-1027-41f7-ad4d-173115ed8ec1	1
5206	individual	2190	f10eab25-ab4b-444f-b1b5-15a1a5948024	7
5212	individual	2190	a2d88e69-d575-45ec-9b52-0dc3a51468ed	7
5218	individual	2190	dbd027dc-9587-422f-a8be-c7c1ddd08691	7
5225	individual	2192	892ab105-f212-407f-8fb4-58ec59310a5e	7
5228	individual	2192	654b0931-1027-41f7-ad4d-173115ed8ec1	1
5231	individual	2192	f10eab25-ab4b-444f-b1b5-15a1a5948024	7
5237	individual	2192	a2d88e69-d575-45ec-9b52-0dc3a51468ed	7
5243	individual	2192	dbd027dc-9587-422f-a8be-c7c1ddd08691	7
5250	individual	2194	892ab105-f212-407f-8fb4-58ec59310a5e	7
5259	individual	2194	dbd027dc-9587-422f-a8be-c7c1ddd08691	7
5265	individual	2194	a2d88e69-d575-45ec-9b52-0dc3a51468ed	7
5271	individual	2194	f10eab25-ab4b-444f-b1b5-15a1a5948024	7
5274	individual	2194	654b0931-1027-41f7-ad4d-173115ed8ec1	1
5275	individual	2196	892ab105-f212-407f-8fb4-58ec59310a5e	7
5284	individual	2196	dbd027dc-9587-422f-a8be-c7c1ddd08691	7
5290	individual	2196	a2d88e69-d575-45ec-9b52-0dc3a51468ed	7
5296	individual	2196	f10eab25-ab4b-444f-b1b5-15a1a5948024	7
5299	individual	2196	654b0931-1027-41f7-ad4d-173115ed8ec1	1
5300	individual	2198	892ab105-f212-407f-8fb4-58ec59310a5e	7
5303	individual	2198	654b0931-1027-41f7-ad4d-173115ed8ec1	1
5304	individual	2202	892ab105-f212-407f-8fb4-58ec59310a5e	7
5313	individual	2202	dbd027dc-9587-422f-a8be-c7c1ddd08691	7
5319	individual	2202	a2d88e69-d575-45ec-9b52-0dc3a51468ed	7
5325	individual	2202	f10eab25-ab4b-444f-b1b5-15a1a5948024	7
5328	individual	2202	654b0931-1027-41f7-ad4d-173115ed8ec1	1
5329	individual	2204	892ab105-f212-407f-8fb4-58ec59310a5e	7
5338	individual	2204	dbd027dc-9587-422f-a8be-c7c1ddd08691	7
5344	individual	2204	a2d88e69-d575-45ec-9b52-0dc3a51468ed	7
5350	individual	2204	f10eab25-ab4b-444f-b1b5-15a1a5948024	7
5353	individual	2204	654b0931-1027-41f7-ad4d-173115ed8ec1	1
5354	individual	2206	892ab105-f212-407f-8fb4-58ec59310a5e	7
5363	individual	2206	dbd027dc-9587-422f-a8be-c7c1ddd08691	7
5369	individual	2206	a2d88e69-d575-45ec-9b52-0dc3a51468ed	7
5375	individual	2206	f10eab25-ab4b-444f-b1b5-15a1a5948024	7
5378	individual	2206	654b0931-1027-41f7-ad4d-173115ed8ec1	1
5379	individual	2208	892ab105-f212-407f-8fb4-58ec59310a5e	7
5388	individual	2208	dbd027dc-9587-422f-a8be-c7c1ddd08691	7
5394	individual	2208	a2d88e69-d575-45ec-9b52-0dc3a51468ed	7
5400	individual	2208	f10eab25-ab4b-444f-b1b5-15a1a5948024	7
5403	individual	2208	654b0931-1027-41f7-ad4d-173115ed8ec1	1
5404	individual	2212	892ab105-f212-407f-8fb4-58ec59310a5e	31
5407	individual	2212	654b0931-1027-41f7-ad4d-173115ed8ec1	1
5408	individual	2214	892ab105-f212-407f-8fb4-58ec59310a5e	31
5411	individual	2214	654b0931-1027-41f7-ad4d-173115ed8ec1	1
6057	individual	2360	892ab105-f212-407f-8fb4-58ec59310a5e	7
6060	individual	2360	654b0931-1027-41f7-ad4d-173115ed8ec1	1
6061	individual	2360	6b1fa42f-8729-4625-80d1-17e4ef691ce7	7
6062	individual	2360	999cd6bf-5cef-4729-8543-696086143884	1
6091	individual	2342	892ab105-f212-407f-8fb4-58ec59310a5e	7
6094	individual	2342	654b0931-1027-41f7-ad4d-173115ed8ec1	1
6095	individual	2342	6b1fa42f-8729-4625-80d1-17e4ef691ce7	7
6096	individual	2342	999cd6bf-5cef-4729-8543-696086143884	1
6183	individual	134	892ab105-f212-407f-8fb4-58ec59310a5e	7
6186	individual	134	654b0931-1027-41f7-ad4d-173115ed8ec1	1
6187	individual	134	6b1fa42f-8729-4625-80d1-17e4ef691ce7	1
6188	individual	134	999cd6bf-5cef-4729-8543-696086143884	1
6222	individual	2436	892ab105-f212-407f-8fb4-58ec59310a5e	31
6225	individual	2436	654b0931-1027-41f7-ad4d-173115ed8ec1	1
6435	individual	171	892ab105-f212-407f-8fb4-58ec59310a5e	31
6438	individual	171	654b0931-1027-41f7-ad4d-173115ed8ec1	1
6439	individual	171	6b1fa42f-8729-4625-80d1-17e4ef691ce7	1
6440	individual	171	999cd6bf-5cef-4729-8543-696086143884	1
8187	individual	3021	892ab105-f212-407f-8fb4-58ec59310a5e	7
8190	individual	3021	654b0931-1027-41f7-ad4d-173115ed8ec1	1
8241	individual	3052	892ab105-f212-407f-8fb4-58ec59310a5e	7
8244	individual	3052	654b0931-1027-41f7-ad4d-173115ed8ec1	1
8245	individual	3054	892ab105-f212-407f-8fb4-58ec59310a5e	7
8248	individual	3054	654b0931-1027-41f7-ad4d-173115ed8ec1	1
8249	individual	3054	6b1fa42f-8729-4625-80d1-17e4ef691ce7	1
8250	individual	3054	999cd6bf-5cef-4729-8543-696086143884	1
9453	individual	3016	892ab105-f212-407f-8fb4-58ec59310a5e	7
9456	individual	3016	654b0931-1027-41f7-ad4d-173115ed8ec1	1
11059	individual	5978	892ab105-f212-407f-8fb4-58ec59310a5e	31
11068	individual	5978	dbd027dc-9587-422f-a8be-c7c1ddd08691	7
11074	individual	5978	a2d88e69-d575-45ec-9b52-0dc3a51468ed	7
11080	individual	5978	f10eab25-ab4b-444f-b1b5-15a1a5948024	7
11086	individual	5978	654b0931-1027-41f7-ad4d-173115ed8ec1	1
11716	com.dotmarketing.beans.Host	SYSTEM_HOST	654b0931-1027-41f7-ad4d-173115ed8ec1	1
11717	com.dotmarketing.portlets.folders.model.Folder	SYSTEM_HOST	654b0931-1027-41f7-ad4d-173115ed8ec1	1
11718	com.dotmarketing.portlets.files.model.File	SYSTEM_HOST	654b0931-1027-41f7-ad4d-173115ed8ec1	1
11719	com.dotmarketing.portlets.links.model.Link	SYSTEM_HOST	654b0931-1027-41f7-ad4d-173115ed8ec1	1
11720	com.dotmarketing.portlets.contentlet.model.Contentlet	SYSTEM_HOST	654b0931-1027-41f7-ad4d-173115ed8ec1	1
11721	com.dotmarketing.portlets.htmlpageasset.model.IHTMLPage	SYSTEM_HOST	654b0931-1027-41f7-ad4d-173115ed8ec1	1
11722	com.dotmarketing.portlets.structure.model.Structure	SYSTEM_HOST	654b0931-1027-41f7-ad4d-173115ed8ec1	1
11727	com.dotmarketing.portlets.categories.model.Category	SYSTEM_HOST	654b0931-1027-41f7-ad4d-173115ed8ec1	1
11761	com.dotmarketing.beans.Host	48190c8c-42c4-46af-8d1a-0cd5db894797	654b0931-1027-41f7-ad4d-173115ed8ec1	1
11778	com.dotmarketing.portlets.htmlpageasset.model.IHTMLPage	SYSTEM_HOST	d3e78673-044a-4e1e-a38a-56f48cc6d5a5	31
12104	individual	0720cd4f-4095-4e8a-8f73-2e34d7e099e4	edecd377-2321-4803-aa8b-89797dd0d61f	1
12126	individual	365d9758-8312-414d-8c1e-b7b0b3df7964	02ae46fa-cb67-4ed8-82d5-f1f9a5e1d744	1
12137	individual	5c1579c4-33d1-47c8-9b68-776fa586655e	e7d4e34e-5127-45fc-8123-d48b62d510e3	1
12195	individual	c9ff3ca8-1d46-4397-8c62-e6d2134ec23d	02ae46fa-cb67-4ed8-82d5-f1f9a5e1d744	1
12199	individual	a15fc339-dbad-4f60-b0ec-3cef2ac080cd	02ae46fa-cb67-4ed8-82d5-f1f9a5e1d744	1
12218	individual	48190c8c-42c4-46af-8d1a-0cd5db894797	654b0931-1027-41f7-ad4d-173115ed8ec1	17
12219	com.dotmarketing.portlets.files.model.File	48190c8c-42c4-46af-8d1a-0cd5db894797	654b0931-1027-41f7-ad4d-173115ed8ec1	1
12220	com.dotmarketing.portlets.htmlpageasset.model.IHTMLPage	48190c8c-42c4-46af-8d1a-0cd5db894797	654b0931-1027-41f7-ad4d-173115ed8ec1	1
12221	com.dotmarketing.portlets.folders.model.Folder	48190c8c-42c4-46af-8d1a-0cd5db894797	654b0931-1027-41f7-ad4d-173115ed8ec1	1
12222	com.dotmarketing.portlets.contentlet.model.Contentlet	48190c8c-42c4-46af-8d1a-0cd5db894797	654b0931-1027-41f7-ad4d-173115ed8ec1	3
12223	com.dotmarketing.portlets.links.model.Link	48190c8c-42c4-46af-8d1a-0cd5db894797	654b0931-1027-41f7-ad4d-173115ed8ec1	1
12224	com.dotmarketing.portlets.structure.model.Structure	48190c8c-42c4-46af-8d1a-0cd5db894797	654b0931-1027-41f7-ad4d-173115ed8ec1	3
12227	individual	d91fcab5-e645-4f64-bd80-c8a9d1999434	654b0931-1027-41f7-ad4d-173115ed8ec1	3
12228	individual	d91fcab5-e645-4f64-bd80-c8a9d1999434	db0d2bca-5da5-4c18-b5d7-87f02ba58eb6	23
12229	individual	a4345272-d573-477e-b6d1-fc19d92bdc11	02ae46fa-cb67-4ed8-82d5-f1f9a5e1d744	1
12234	individual	006b7ad6-8d9c-4e5b-97b3-eab1b5524de9	654b0931-1027-41f7-ad4d-173115ed8ec1	23
12287	individual	48190c8c-42c4-46af-8d1a-0cd5db894797	db0d2bca-5da5-4c18-b5d7-87f02ba58eb6	1
12348	individual	5ce9a411-725b-43ef-8403-ae90909a5579	e36988eb-f206-4fd3-a06c-6a746d30a772	1
12349	individual	2a795970-6660-4ae5-b9fc-1442607b9efa	02ae46fa-cb67-4ed8-82d5-f1f9a5e1d744	1
12383	individual	41ab99b4-2779-46a8-a717-b099b57e3299	02ae46fa-cb67-4ed8-82d5-f1f9a5e1d744	1
12384	individual	ba74c14e-8019-482d-85cb-e6f9d39bdfdd	e36988eb-f206-4fd3-a06c-6a746d30a772	1
12390	individual	4e1efa41-789e-4f63-8e7f-30f5697e53e3	02ae46fa-cb67-4ed8-82d5-f1f9a5e1d744	1
12394	individual	659751a5-a5e3-40ed-a799-e3aa7a83dfd8	02ae46fa-cb67-4ed8-82d5-f1f9a5e1d744	1
12414	individual	ced34d22-b1ed-4a6e-a89b-e5f93192cc3f	654b0931-1027-41f7-ad4d-173115ed8ec1	1
12433	individual	44d4d4cd-c812-49db-adb1-1030be73e69a	654b0931-1027-41f7-ad4d-173115ed8ec1	1
12434	individual	c8a03c24-277a-49a5-b5e0-7f99490a004d	654b0931-1027-41f7-ad4d-173115ed8ec1	1
12435	individual	f0f370ae-51c6-4be0-b48d-37ee098ca45b	654b0931-1027-41f7-ad4d-173115ed8ec1	1
12437	individual	6ae6ab66-0f89-44ab-9998-df400e50917d	e7d4e34e-5127-45fc-8123-d48b62d510e3	1
12438	individual	ed139dd6-3a7d-4b8b-8a4d-9620d3c8a9ab	0d1efa06-a392-44ad-8ace-28c1906043df	1
12447	individual	4958588d-9c8e-40e4-bfcb-4ded40bd099f	c3eb4526-6d96-48d8-9540-e5fa560cfc0f	1
12473	individual	43b1713b-4257-4478-9aad-25bda483e014	617f7300-5c7b-463f-9554-380b918520bc	1
12478	individual	032a6fa0-1df7-479a-9bf1-51892e3b2a02	654b0931-1027-41f7-ad4d-173115ed8ec1	1
12534	individual	2a3e91e4-fbbf-4876-8c5b-2233c1739b05	654b0931-1027-41f7-ad4d-173115ed8ec1	1
12535	com.dotmarketing.portlets.contentlet.model.Contentlet	2a3e91e4-fbbf-4876-8c5b-2233c1739b05	654b0931-1027-41f7-ad4d-173115ed8ec1	1
12540	individual	a007def2-896d-4fd1-843b-d3abb5305f3f	654b0931-1027-41f7-ad4d-173115ed8ec1	7
12541	com.dotmarketing.portlets.contentlet.model.Contentlet	a007def2-896d-4fd1-843b-d3abb5305f3f	654b0931-1027-41f7-ad4d-173115ed8ec1	7
12542	individual	4d21b6d8-1711-4ae6-9419-89e2b1ae5a06	892ab105-f212-407f-8fb4-58ec59310a5e	63
12543	individual	4d21b6d8-1711-4ae6-9419-89e2b1ae5a06	654b0931-1027-41f7-ad4d-173115ed8ec1	7
12544	com.dotmarketing.portlets.contentlet.model.Contentlet	4d21b6d8-1711-4ae6-9419-89e2b1ae5a06	654b0931-1027-41f7-ad4d-173115ed8ec1	7
12545	individual	4d21b6d8-1711-4ae6-9419-89e2b1ae5a06	29e0af9e-0e60-48ee-b9f7-1453d94d9cb6	7
12546	com.dotmarketing.portlets.contentlet.model.Contentlet	4d21b6d8-1711-4ae6-9419-89e2b1ae5a06	29e0af9e-0e60-48ee-b9f7-1453d94d9cb6	7
12579	individual	45f2136e-a567-49e0-8e22-155019ccfc1c	c3eb4526-6d96-48d8-9540-e5fa560cfc0f	1
12580	individual	f1e3e786-9095-4157-b756-ffc767e2cc12	c3eb4526-6d96-48d8-9540-e5fa560cfc0f	1
12581	individual	8beed083-8999-4bb4-914b-ea0457cf9fd4	617f7300-5c7b-463f-9554-380b918520bc	1
12582	individual	89685558-1449-4928-9cff-adda8648d54d	c3eb4526-6d96-48d8-9540-e5fa560cfc0f	1
12583	individual	175009d6-9e4b-4ed2-ae31-7d019d3dc278	c3eb4526-6d96-48d8-9540-e5fa560cfc0f	1
12584	individual	d4b61549-84e3-4e8e-8182-8e34f12f9063	617f7300-5c7b-463f-9554-380b918520bc	1
12585	individual	88794a29-d861-4aa5-b137-9a6af72c6fc0	617f7300-5c7b-463f-9554-380b918520bc	1
12587	individual	f2bb86bc-f5e8-470c-8771-0eea77ac46a7	02ae46fa-cb67-4ed8-82d5-f1f9a5e1d744	1
12589	individual	e2021cf0-1811-4e08-aacc-420be3441c36	654b0931-1027-41f7-ad4d-173115ed8ec1	1
12590	individual	d6cfc127-31e8-47aa-bd5e-77434d06c24f	02ae46fa-cb67-4ed8-82d5-f1f9a5e1d744	1
12591	individual	64fa7b51-bfc4-4686-8775-70a8cd44aee7	e36988eb-f206-4fd3-a06c-6a746d30a772	1
12592	individual	edff488f-b973-4ae1-bcae-82d27af64b05	e36988eb-f206-4fd3-a06c-6a746d30a772	1
12593	individual	7309ed0d-cbf9-4b02-aa3c-8b599fd2a718	617f7300-5c7b-463f-9554-380b918520bc	1
12594	individual	808a2c19-84f1-4f49-a91d-c610714c370d	617f7300-5c7b-463f-9554-380b918520bc	1
12595	individual	808a2c19-84f1-4f49-a91d-c610714c370d	db0d2bca-5da5-4c18-b5d7-87f02ba58eb6	1
12596	individual	7d6aba45-a53d-4b81-a598-e2fd4207efb4	e36988eb-f206-4fd3-a06c-6a746d30a772	1
12597	individual	8030e2bd-29da-4926-9968-0da683d13658	654b0931-1027-41f7-ad4d-173115ed8ec1	1
12598	individual	1b107324-38e8-4148-b148-21fce850cffc	c3eb4526-6d96-48d8-9540-e5fa560cfc0f	1
12600	individual	134a50d3-782d-43de-8877-42c0be1c86a4	617f7300-5c7b-463f-9554-380b918520bc	1
12601	individual	777f1c6b-c877-4a37-ba4b-10627316c2cc	c3eb4526-6d96-48d8-9540-e5fa560cfc0f	1
12602	individual	000ec468-0a63-4283-beb7-fcb36c107b2f	c3eb4526-6d96-48d8-9540-e5fa560cfc0f	1
12605	individual	c92f9aa1-9503-4567-ac30-d3242b54d02d	617f7300-5c7b-463f-9554-380b918520bc	1
12606	individual	38efc763-d78f-4e4b-b092-59cd8c579b93	c3eb4526-6d96-48d8-9540-e5fa560cfc0f	1
12609	individual	00f8b4c1-9eba-4271-809b-47d27bf6a5c0	c3eb4526-6d96-48d8-9540-e5fa560cfc0f	1
12612	individual	62078964-3ed4-4729-91d3-75e841736905	02ae46fa-cb67-4ed8-82d5-f1f9a5e1d744	1
12621	individual	963f6a04-5320-42e7-ab74-6d876d199946	654b0931-1027-41f7-ad4d-173115ed8ec1	1
12622	individual	897cf4a9-171a-4204-accb-c1b498c813fe	654b0931-1027-41f7-ad4d-173115ed8ec1	7
12623	com.dotmarketing.portlets.contentlet.model.Contentlet	897cf4a9-171a-4204-accb-c1b498c813fe	654b0931-1027-41f7-ad4d-173115ed8ec1	7
12644	individual	53e09c7a-b372-4fb4-a2ee-f5f6c1671793	617f7300-5c7b-463f-9554-380b918520bc	1
12649	individual	4da13a42-5d59-480c-ad8f-94a3adf809fe	617f7300-5c7b-463f-9554-380b918520bc	1
12650	individual	1e0f1c6b-b67f-4c99-983d-db2b4bfa88b2	c3eb4526-6d96-48d8-9540-e5fa560cfc0f	1
12653	individual	ceca71a0-deee-4999-bd47-b01baa1bcfc8	617f7300-5c7b-463f-9554-380b918520bc	1
12655	individual	b9d89c80-3d88-4311-8365-187323c96436	c3eb4526-6d96-48d8-9540-e5fa560cfc0f	1
12665	individual	db881b3b-60b0-4b7d-8e85-d80887ae2978	e7d4e34e-5127-45fc-8123-d48b62d510e3	1
12666	individual	9b28db26-13bc-421b-98ab-87b97cce7216	e7d4e34e-5127-45fc-8123-d48b62d510e3	1
12667	individual	ae569f3a-c96f-4c44-926c-4741b2ad344f	e7d4e34e-5127-45fc-8123-d48b62d510e3	1
\.


--
-- Data for Name: permission_reference; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.permission_reference (id, asset_id, reference_id, permission_type) FROM stdin;
1486	d0d0aa0f-8aba-416c-8951-f3e8fe9f20cc	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1487	f58cf618-df78-481c-b2ce-450bac89273a	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1488	9b9e7218-e086-4c61-991f-6ec22e7d7a82	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1489	0c556e37-99e0-4458-a2cd-d42cc7a11045	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1490	9469fbf0-9fc2-451d-94d9-5fbfde5b5974	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1491	ea887e3a-1e9d-47cf-995a-ce060ae1fc4e	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1492	95e0af1d-bf6a-46ca-b0f7-665b23d00be3	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1493	fdc739f6-fe53-4271-9c8c-a3e05d12fcac	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1494	c2470fd2-9687-4041-ac58-784894171840	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1495	593ef32c-2f01-4277-a6a9-2250fd5bb5fe	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1496	64269d16-2710-4919-88ec-3b09c89ea004	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1497	683ea6c2-5d33-4363-8061-c811b1381f25	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1498	69370958-2898-4d1e-96ad-ab14278ad961	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1499	0b280c00-834f-4721-a48e-2f4df97607ea	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1500	a9d7d59a-8ff8-4ee3-84c0-e49f6312b185	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1501	965059bc-25b4-44b0-add8-b6fc5144be9d	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1502	bca97d30-14f3-418d-8827-a2799c5e9a0c	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1503	040d7fdf-fb31-4a92-867b-a67bccdfca29	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1504	ed39ed50-0118-4ac2-b047-a8c0960dbd48	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1505	ba1002d7-d4db-4019-b242-8118054051a4	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1506	50042108-38ec-48ba-be91-7f4368c8630f	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1507	2b457e67-9c94-4cb3-8d1b-422fbe4fd5a0	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1508	35fe888d-1555-43ad-b155-080dd7d9b9cf	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1509	e357b275-3cc8-455b-b7d7-0adaefb51040	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1510	3826636b-cc3a-46b2-97c5-ce6bdb377fcb	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1511	5bf7da04-f79c-4a31-8eee-fddc2b157421	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1512	6ffd89b1-3484-4a17-b5b4-e96ecdc6b4f9	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1513	76534a2a-04cd-4fd7-b891-0a1e61b1a859	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1514	cff6f9a9-d0f3-45c2-9370-dc0457c6bbf0	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1515	17dfb289-ee8c-4e88-8cb4-ec036c999174	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1516	5ff402db-77c2-499c-a7db-a62d31d86cc4	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1517	22236f46-f887-4c57-ae80-6a929e7bc4c1	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1518	0cb1654b-90e8-4ff5-b8c1-0dcc0508f6ef	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1519	5a322949-aca5-4518-9920-fbd4de84a82d	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1520	2d0fcd52-e3ca-4f33-91e8-baff8db7b88e	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1521	7ca937a7-a2b0-4da6-b8f7-a26dffda3827	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1522	d03bcbfe-b67b-482c-ba1d-24fb5f6c5dc2	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1523	46bf0614-73ac-48c5-a59f-fc5b883eabe3	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1524	dee9deb8-6ed9-45d8-80d4-efc4614d2113	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1525	c4500d42-30da-413d-aca9-7b56f844a055	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1526	2d0683c7-a8ad-406d-a4d5-ec47899a902b	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1527	b0457d83-b3aa-46d2-a6f8-cbc553780f33	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1528	dc557d44-d90e-4a3c-ba8f-4cc9ee164fda	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1529	5227bb4e-7b53-4777-af63-da789c40404d	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1530	591cc010-2cf8-4da3-b75d-53dee0107062	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1531	1f26789c-c4a9-4ceb-835b-cecdcead54ee	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1532	0bbbb312-52f7-4993-8af1-a87a9ea5ef2b	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1533	9ce3e0fd-7578-421b-8241-59f6ed3adbd8	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1534	f58f3fd8-7808-4074-b520-8edb531521e2	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1535	c41cf5a6-3312-4e3b-b419-0f7d972f3305	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1536	968b8147-92ba-458d-9fe1-941d9f7c0415	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1537	6828d30e-b9ec-48c7-b96c-81ef01a0a3b1	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1538	1344e901-59ce-4d2d-96ae-90adcf1a5092	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1539	2c69bb81-0f25-4a05-8d10-918b5b40a24b	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1540	339be8a8-d6aa-4196-b20e-a0ebc5c82037	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1541	052e6ccf-408c-43b7-a9d8-6a9505561ae2	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1542	aed0ee71-a4b8-4afe-8a14-339f79ec5a6f	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1543	53fd322d-7f6d-4796-ba88-3880a256f13c	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1544	ea37dc2f-328b-452f-b05b-265a8a48382d	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1545	9ac7acb5-cef0-48fd-8cf4-963059442f2c	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1546	8257a204-4cc2-48d6-b73f-189c34aedc2c	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1547	38bba30b-47d1-4c9c-a6d3-63b6e30b529a	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1548	5d585f86-15ec-42a4-9a1a-87e57959cfbf	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1549	96e19b30-4f82-4a40-82ed-e8640962be93	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1550	5389e6a5-ee91-4164-b6ad-cc4f695f1d84	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1551	4341f0fd-a456-4d77-83da-a5cd7248624d	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1552	a55a982f-2b8f-4672-8a5a-f4560a42ec1d	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1553	d1ec7b30-8e9e-4b3e-b075-9cd9557fee8b	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1554	4bb72d3b-e572-4910-8fc2-d725279adeb5	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
1555	86a1e1fe-c026-49f7-91c9-3fb5a77e0172	SYSTEM_HOST	com.dotmarketing.portlets.templates.design.bean.TemplateLayout
\.


--
-- Name: permission_reference_seq; Type: SEQUENCE SET; Schema: public; Owner: dotcms_dev
--

SELECT pg_catalog.setval('public.permission_reference_seq', 1555, true);


--
-- Name: permission_seq; Type: SEQUENCE SET; Schema: public; Owner: dotcms_dev
--

SELECT pg_catalog.setval('public.permission_seq', 12668, false);


--
-- Data for Name: plugin; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.plugin (id, plugin_name, plugin_version, author, first_deployed_date, last_deployed_date) FROM stdin;
com.dotcms.config	dotCMS Config	1.0	dotCMS	2010-06-17 00:00:00	2010-06-17 00:00:00
org.dotcms.plugins.htmlPageExtension	HTML Page Extension	1.3	dotCMS	2012-06-22 15:02:28.218	2012-06-22 15:02:28.218
starter.config.plugin	dotCMS Config	1.0	dotCMS	2012-05-31 00:00:00	2012-05-31 00:00:00
starter.dotcms.config	dotCMS Config	1.0	dotCMS	2014-10-06 12:32:35.603	2014-10-06 12:32:35.603
\.


--
-- Data for Name: plugin_property; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.plugin_property (plugin_id, propkey, original_value, current_value) FROM stdin;
org.dotcms.plugins.htmlPageExtension	NEW_HTMLPAGE_EXTENSION	html	html
org.dotcms.plugins.htmlPageExtension	reload.force	true	true
org.dotcms.plugins.htmlPageExtension	OLD_HTMLPAGE_EXTENSION	dot	dot
\.


--
-- Data for Name: pollschoice; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.pollschoice (choiceid, questionid, description) FROM stdin;
\.


--
-- Data for Name: pollsdisplay; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.pollsdisplay (layoutid, userid, portletid, questionid) FROM stdin;
\.


--
-- Data for Name: pollsquestion; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.pollsquestion (questionid, portletid, groupid, companyid, userid, username, createdate, modifieddate, title, description, expirationdate, lastvotedate) FROM stdin;
\.


--
-- Data for Name: pollsvote; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.pollsvote (questionid, userid, choiceid, votedate) FROM stdin;
\.


--
-- Data for Name: portlet; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.portlet (portletid, groupid, companyid, defaultpreferences, narrow, roles, active_) FROM stdin;
9	SHARED_KEY	dotcms.org	<portlet-preferences>\r\n  <preference>\r\n  <name>MenuItems</name> \r\n  <value>\r\n    <menu-items>\r\n\t\t    <!-- New Menu Items-->\r\n\t\t    <menu-item position="top">\r\n\t\t    \t<name>New</name>\r\n\t\t    \t<icon>/html/skin/image/dotcms/icons/page_new.gif</icon>\r\n\t\t    \t<assoc-portlet />\r\n\t\t    \t<params />\r\n\t\t    \t<submenu>\r\n\t\t\t\t  \t<menu-item>\r\n\t\t\t\t\t  \t<name>Group</name>\r\n\t\t\t\t\t  \t<icon>/html/skin/image/dotcms/icons/group_add.gif</icon>\r\n\t\t\t\t\t  \t<assoc-portlet>9</assoc-portlet>\r\n\t\t\t\t\t  \t<render />\r\n\t\t\t\t\t  \t<params>\r\n\t\t\t\t\t  \t\t<param>\r\n\t\t\t\t\t  \t\t\t<name>struts_action</name>\r\n\t\t\t\t\t  \t\t\t<value>/admin/list_groups</value>\r\n\t\t\t\t\t  \t\t</param>\r\n\t\t\t\t\t  \t</params>\r\n\t\t\t\t  \t</menu-item>\r\n\t\t\t\t  \t<menu-item>\r\n\t\t\t\t\t  \t<name>Role</name>\r\n\t\t\t\t\t  \t<icon>/html/skin/image/dotcms/icons/status_online_add.gif</icon>\r\n\t\t\t\t\t  \t<assoc-portlet>9</assoc-portlet>\r\n\t\t\t\t\t  \t<render />\r\n\t\t\t\t\t  \t<params>\r\n\t\t\t\t\t  \t\t<param>\r\n\t\t\t\t\t  \t\t\t<name>struts_action</name>\r\n\t\t\t\t\t  \t\t\t<value>/admin/list_roles</value>\r\n\t\t\t\t\t  \t\t</param>\r\n\t\t\t\t\t  \t</params>\r\n\t\t\t\t  \t</menu-item>\r\n\t\t    \t</submenu>\r\n\t\t\t\t </menu-item>\r\n\t\t    <!-- Non-New Menu Items-->\r\n\t\t  \t<menu-item>\r\n\t\t\t  \t<name>Permissions</name>\r\n\t\t\t  \t<icon>/html/skin/image/dotcms/icons/lock.gif</icon>\r\n\t\t\t  \t<assoc-portlet>9</assoc-portlet>\r\n\t\t\t  \t<render />\r\n\t\t\t  \t<params>\r\n\t\t\t  \t\t<param>\r\n\t\t\t  \t\t\t<name>struts_action</name>\r\n\t\t\t  \t\t\t<value>/admin/view</value>\r\n\t\t\t  \t\t</param>\r\n\t\t\t  \t</params>\r\n\t\t\t  \t<submenu>\r\n\t\t\t\t  \t<menu-item>\r\n\t\t\t\t\t  \t<name>Groups</name>\r\n\t\t\t\t\t  \t<icon>/html/skin/image/dotcms/icons/group_key.gif</icon>\r\n\t\t\t\t\t  \t<assoc-portlet>9</assoc-portlet>\r\n\t\t\t\t\t  \t<render />\r\n\t\t\t\t\t  \t<params>\r\n\t\t\t\t\t  \t\t<param>\r\n\t\t\t\t\t  \t\t\t<name>struts_action</name>\r\n\t\t\t\t\t  \t\t\t<value>/admin/list_groups</value>\r\n\t\t\t\t\t  \t\t</param>\r\n\t\t\t\t\t  \t</params>\r\n\t\t\t\t  \t</menu-item>\r\n\t\t\t\t  \t<menu-item>\r\n\t\t\t\t\t  \t<name>Roles</name>\r\n\t\t\t\t\t  \t<icon>/html/skin/image/dotcms/icons/status_online_key.gif</icon>\r\n\t\t\t\t\t  \t<assoc-portlet>9</assoc-portlet>\r\n\t\t\t\t\t  \t<render />\r\n\t\t\t\t\t  \t<params>\r\n\t\t\t\t\t  \t\t<param>\r\n\t\t\t\t\t  \t\t\t<name>struts_action</name>\r\n\t\t\t\t\t  \t\t\t<value>/admin/list_roles</value>\r\n\t\t\t\t\t  \t\t</param>\r\n\t\t\t\t\t  \t</params>\r\n\t\t\t\t  \t</menu-item>\r\n\t\t\t\t  \t<menu-item>\r\n\t\t\t\t\t  \t<name>Portlets</name>\r\n\t\t\t\t\t  \t<icon>/html/skin/image/dotcms/icons/application_cascade_key.gif</icon>\r\n\t\t\t\t\t  \t<assoc-portlet>9</assoc-portlet>\r\n\t\t\t\t\t  \t<render />\r\n\t\t\t\t\t  \t<params>\r\n\t\t\t\t\t  \t\t<param>\r\n\t\t\t\t\t  \t\t\t<name>struts_action</name>\r\n\t\t\t\t\t  \t\t\t<value>/admin/list_portlets</value>\r\n\t\t\t\t\t  \t\t</param>\r\n\t\t\t\t\t  \t</params>\r\n\t\t\t\t  \t</menu-item>\r\n\t\t\t  \t</submenu>\r\n\t\t  \t</menu-item>\r\n\t    </menu-items>\r\n    </value> \r\n  </preference>\r\n</portlet-preferences>	t	Administrator,	t
EXT_11	SHARED_KEY	dotcms.org	<portlet-preferences>\r\n  <preference>\r\n  <name>MenuItems</name> \r\n  <value>\r\n    <menu-items>\r\n\t\t    <!-- New Menu Items-->\r\n\t\t    <menu-item position="top">\r\n\t\t    \t<name>New</name>\r\n\t\t    \t<icon>/html/skin/image/dotcms/icons/page_new.gif</icon>\r\n\t\t    \t<assoc-portlet>EXT_11</assoc-portlet>\r\n\t\t    \t<show-contentlets />\r\n\t\t    \t<params />\r\n\t\t    \t<submenu/>\r\n\t\t    </menu-item>\r\n\t\t    <!-- Non-New Menu Items-->\r\n\t\t  \t<menu-item>\r\n\t\t\t  \t<name>Search Contents</name>\r\n\t\t\t  \t<icon>/html/skin/image/dotcms/icons/newspaper_search.gif</icon>\r\n\t\t\t  \t<assoc-portlet>EXT_11</assoc-portlet>\r\n\t\t\t  \t<params>\r\n\t\t\t  \t\t<param>\r\n\t\t\t  \t\t\t<name>struts_action</name>\r\n\t\t\t  \t\t\t<value>/ext/contentlet/view_contentlets</value>\r\n\t\t\t  \t\t</param>\r\n\t\t\t  \t</params>\r\n\t\t  \t</menu-item>\r\n\t\t  \t<menu-item>\r\n\t\t\t  \t<name>Import Content</name>\r\n\t\t\t  \t<icon>/html/skin/image/dotcms/icons/newspaper_up.gif</icon>\r\n\t\t\t  \t<assoc-portlet>EXT_11</assoc-portlet>\r\n\t\t\t  \t<params>\r\n\t\t\t  \t\t<param>\r\n\t\t\t  \t\t\t<name>struts_action</name>\r\n\t\t\t  \t\t\t<value>/ext/contentlet/import_contentlets</value>\r\n\t\t\t  \t\t</param>\r\n\t\t\t  \t</params>\r\n\t\t  \t</menu-item>\r\n\t    </menu-items>\r\n    </value> \r\n  </preference>\r\n</portlet-preferences>	t	CMS Administrator,CMS User,	t
EXT_13	SHARED_KEY	dotcms.org	<portlet-preferences></portlet-preferences>	t	CMS Administrator,	t
EXT_16	SHARED_KEY	dotcms.org	<portlet-preferences>\r\n  <preference>\r\n  <name>MenuItems</name> \r\n  <value>\r\n    <menu-items>\r\n\t\t    <!-- New Menu Items-->\r\n\t\t    <menu-item position="top">\r\n\t\t    \t<name>New</name>\r\n\t\t    \t<icon>/html/skin/image/dotcms/icons/page_new.gif</icon>\r\n\t\t    \t<assoc-portlet>EXT_16</assoc-portlet>\r\n\t\t    \t<params />\r\n\t\t    \t<submenu>\r\n\t\t\t\t  \t<menu-item>\r\n\t\t\t\t\t  \t<name>Mailing List</name>\r\n\t\t\t\t\t  \t<icon>/html/skin/image/dotcms/icons/email_group_add.gif</icon>\r\n\t\t\t\t\t  \t<assoc-portlet>EXT_16</assoc-portlet>\r\n\t\t\t\t\t\t  \t<params>\r\n\t\t\t\t\t\t  \t\t<param>\r\n\t\t\t\t\t\t  \t\t\t<name>struts_action</name>\r\n\t\t\t\t\t\t  \t\t\t<value>/ext/usermanager/view_usermanagerlist</value>\r\n\t\t\t\t\t\t  \t\t</param>\r\n\t\t\t\t\t\t  \t</params>\r\n\t\t\t\t  \t</menu-item>\r\n\t\t    \t</submenu>\r\n\t\t    </menu-item>\r\n\t\t    <!-- Non-New Menu Items-->\r\n\t\t  \t<menu-item>\r\n\t\t\t  \t<name>Mailing Lists</name>\r\n\t\t\t  \t<icon>/html/skin/image/dotcms/icons/email_group.gif</icon>\r\n\t\t\t  \t<assoc-portlet>EXT_16</assoc-portlet>\r\n\t\t\t\t  \t<params>\r\n\t\t\t\t  \t\t<param>\r\n\t\t\t\t  \t\t\t<name>struts_action</name>\r\n\t\t\t\t  \t\t\t<value>/ext/mailinglists/view_mailinglists</value>\r\n\t\t\t\t  \t\t</param>\r\n\t\t\t\t  \t</params>\r\n\t\t  \t</menu-item>\r\n\t    </menu-items>\r\n    </value> \r\n  </preference>\r\n</portlet-preferences>	f	Mailing Lists Administrator,Mailing List Editor,User Manager Administrator,	t
EXT_19	SHARED_KEY	dotcms.org	<portlet-preferences>\r\n  <preference>\r\n  <name>MenuItems</name> \r\n  <value>\r\n    <menu-items>\r\n\t\t    <!-- New Menu Items-->\r\n\t\t    <menu-item position="top">\r\n\t\t    \t<name>New</name>\r\n\t\t    \t<icon>/html/skin/image/dotcms/icons/page_new.gif</icon>\r\n\t\t    \t<assoc-portlet>EXT_19</assoc-portlet>\r\n\t\t    \t<params />\r\n\t\t    \t<submenu>\r\n\t\t\t\t  \t<menu-item>\r\n\t\t\t\t\t  \t<name>Campaign</name>\r\n\t\t\t\t\t  \t<icon>/html/skin/image/dotcms/icons/transmit_blue_clock_add.gif</icon>\r\n\t\t\t\t\t  \t<assoc-portlet>EXT_19</assoc-portlet>\r\n\t\t\t\t\t  \t<create-campaign />\r\n\t\t\t\t\t\t  \t<params>\r\n\t\t\t\t\t\t  \t\t<param>\r\n\t\t\t\t\t\t  \t\t\t<name>struts_action</name>\r\n\t\t\t\t\t\t  \t\t\t<value>/ext/campaigns/edit_campaign</value>\r\n\t\t\t\t\t\t  \t\t</param>\r\n\t\t\t\t\t\t  \t\t<param>\r\n\t\t\t\t\t\t  \t\t\t<name>cmd</name>\r\n\t\t\t\t\t\t  \t\t\t<value>edit</value>\r\n\t\t\t\t\t\t  \t\t</param>\r\n\t\t\t\t\t\t  \t</params>\r\n\t\t\t\t  \t</menu-item>\r\n\t\t    \t</submenu>\r\n\t\t    </menu-item>\r\n\t\t    <!-- Non-New Menu Items-->\r\n\t\t  \t<menu-item>\r\n\t\t\t  \t<name>Campaigns</name>\r\n\t\t\t  \t<icon>/html/skin/image/dotcms/icons/transmit_blue_clock.gif</icon>\r\n\t\t\t  \t<assoc-portlet>EXT_19</assoc-portlet>\r\n\t\t\t\t  \t<params>\r\n\t\t\t\t  \t\t<param>\r\n\t\t\t\t  \t\t\t<name>struts_action</name>\r\n\t\t\t\t  \t\t\t<value>/ext/campaigns/view_campaigns</value>\r\n\t\t\t\t  \t\t</param>\r\n\t\t\t\t  \t</params>\r\n\t\t  \t</menu-item>\r\n\t    </menu-items>\r\n    </value> \r\n  </preference>\r\n</portlet-preferences>	f	Campaign Manager Admin,Campaign Manager Viewer,Campaign Manager Editor,	t
EXT_4	SHARED_KEY	dotcms.org	<portlet-preferences>\r\n  <preference>\r\n  <name>MenuItems</name> \r\n  <value>\r\n    <menu-items>\r\n\t    <!-- New Menu Items-->\r\n\t    <menu-item position="top">\r\n\t    \t<name>New</name>\r\n\t    \t<icon>/html/skin/image/dotcms/icons/page_new.gif</icon>\r\n\t    \t<assoc-portlet />\r\n\t    \t<params />\r\n\t    \t<submenu>\r\n\t\t\t  \t<menu-item>\r\n\t\t\t\t  \t<name>Category</name>\r\n\t\t\t\t  \t<icon>/html/skin/image/dotcms/icons/chart_organisation_children_add.gif</icon>\r\n\t\t\t\t  \t<assoc-portlet>EXT_4</assoc-portlet>\r\n\t\t\t\t  \t<params>\r\n\t\t\t\t  \t\t<param>\r\n\t\t\t\t  \t\t\t<name>struts_action</name>\r\n\t\t\t\t  \t\t\t<value>/ext/categories/view_category</value>\r\n\t\t\t\t  \t\t</param>\r\n\t\t\t\t  \t</params>\r\n\t\t\t  \t</menu-item>\r\n\t    \t</submenu>\r\n\t    </menu-item>\r\n\t    <!-- Non-New Menu Items-->\r\n\t  \t<menu-item>\r\n\t\t  \t<name>Categories</name>\r\n\t\t  \t<icon>/html/skin/image/dotcms/icons/chart_organisation_children.gif</icon>\r\n\t\t  \t<assoc-portlet>EXT_4</assoc-portlet>\r\n\t\t  \t<params>\r\n\t\t  \t\t<param>\r\n\t\t  \t\t\t<name>struts_action</name>\r\n\t\t  \t\t\t<value>/ext/categories/view_category</value>\r\n\t\t  \t\t</param>\r\n\t\t  \t</params>\r\n\t  \t</menu-item>\r\n    </menu-items>\r\n   </value> \r\n  </preference>\r\n</portlet-preferences>	t	CMS Administrator,CMS User,	t
EXT_6	SHARED_KEY	dotcms.org	<portlet-preferences>\r\n  <preference>\r\n  <name>MenuItems</name> \r\n  <value>\r\n    <menu-items>\r\n\t    <!-- New Menu Items-->\r\n\t\t    <menu-item position="top">\r\n\t\t    \t<name>New</name>\r\n\t\t    \t<icon>/html/skin/image/dotcms/icons/page_new.gif</icon>\r\n\t\t    \t<assoc-portlet />\r\n\t\t    \t<params />\r\n\t\t    \t<submenu>\r\n\t\t\t\t  \t<menu-item>\r\n\t\t\t\t\t  \t<name>Category Group</name>\r\n\t\t\t\t\t  \t<icon>/html/skin/image/dotcms/icons/chart_organisation_add.gif</icon>\r\n\t\t\t\t\t  \t<assoc-portlet>EXT_6</assoc-portlet>\r\n\t\t\t\t\t  \t<params>\r\n\t\t\t\t\t  \t\t<param>\r\n\t\t\t\t\t  \t\t\t<name>struts_action</name>\r\n\t\t\t\t\t  \t\t\t<value>/ext/entities/edit_entity</value>\r\n\t\t\t\t\t  \t\t</param>\r\n\t\t\t\t\t  \t</params>\r\n\t\t\t\t  \t</menu-item>\r\n\t\t    \t</submenu>\r\n\t\t    </menu-item>\r\n\t\t    <!-- Non-New Menu Items-->\r\n\t\t  \t<menu-item>\r\n\t\t\t  \t<name>Category Groups</name>\r\n\t\t\t  \t<icon>/html/skin/image/dotcms/icons/chart_organisation.gif</icon>\r\n\t\t\t  \t<assoc-portlet>EXT_6</assoc-portlet>\r\n\t\t\t  \t<params>\r\n\t\t\t  \t\t<param>\r\n\t\t\t  \t\t\t<name>struts_action</name>\r\n\t\t\t  \t\t\t<value>/ext/entities/view_entities</value>\r\n\t\t\t  \t\t</param>\r\n\t\t\t  \t</params>\r\n\t\t  \t</menu-item>\r\n\t    </menu-items>\r\n    </value> \r\n  </preference>\r\n</portlet-preferences>	t	CMS Administrator,	t
EXT_BROWSER	SHARED_KEY	dotcms.org	<portlet-preferences>\n <preference>\n  <name>MenuItems</name> \n  <value>\n    <!-- New Menu Items-->\n    <menu-items>\n\t    <menu-item position="top">\n\t    \t<name>New</name>\n\t    \t<icon>/html/skin/image/dotcms/icons/page_new.gif</icon>\n\t    \t<assoc-portlet />\n\t    \t<params />\n\t    \t<submenu>\n\t\t\t  \t<menu-item>\n\t\t\t\t  \t<name>HTML Pages</name>\n\t\t\t\t  \t<icon>/html/skin/image/dotcms/icons/page_add.gif</icon>\n\t\t\t\t  \t<assoc-portlet>EXT_15</assoc-portlet>\n\t\t\t\t  \t<params>\n\t\t\t\t  \t\t<param>\n\t\t\t\t  \t\t\t<name>struts_action</name>\n\t\t\t\t  \t\t\t<value>/ext/htmlpages/edit_htmlpage</value>\n\t\t\t\t  \t\t</param>\n\t\t\t\t  \t</params>\n\t\t\t  \t</menu-item>\n\t\t\t  \t<menu-item>\n\t\t\t\t  \t<name>Files</name>\n\t\t\t\t  \t<icon>/html/skin/image/dotcms/icons/page_white_add.gif</icon>\n\t\t\t\t  \t<assoc-portlet>EXT_3</assoc-portlet>\n\t\t\t\t  \t<params>\n\t\t\t\t  \t\t<param>\n\t\t\t\t  \t\t\t<name>struts_action</name>\n\t\t\t\t  \t\t\t<value>/ext/files/edit_file</value>\n\t\t\t\t  \t\t</param>\n\t\t\t\t  \t</params>\n\t\t\t  \t</menu-item>\n\t\t\t  \t<menu-item>\n\t\t\t\t  \t<name>Menu Link</name>\n\t\t\t\t  \t<icon>/html/skin/image/dotcms/icons/link_add.gif</icon>\n\t\t\t\t  \t<assoc-portlet>EXT_18</assoc-portlet>\n\t\t\t\t  \t<params>\n\t\t\t\t  \t\t<param>\n\t\t\t\t  \t\t\t<name>struts_action</name>\n\t\t\t\t  \t\t\t<value>/ext/links/edit_link</value>\n\t\t\t\t  \t\t</param>\n\t\t\t\t  \t\t<param>\n\t\t\t\t  \t\t\t<name>cmd</name>\n\t\t\t\t  \t\t\t<value>edit</value>\n\t\t\t\t  \t\t</param>\n\t\t\t\t  \t</params>\n\t\t\t  \t</menu-item>\n\t\t\t  \t<menu-item>\n\t\t\t\t  \t<name>Container</name>\n\t\t\t\t  \t<icon>/html/skin/image/dotcms/icons/package_add.gif</icon>\n\t\t\t\t  \t<assoc-portlet>EXT_12</assoc-portlet>\n\t\t\t\t  \t<params>\n\t\t\t\t  \t\t<param>\n\t\t\t\t  \t\t\t<name>struts_action</name>\n\t\t\t\t  \t\t\t<value>/ext/containers/edit_container</value>\n\t\t\t\t  \t\t</param>\n\t\t\t\t  \t</params>\n\t\t\t  \t</menu-item>\n\t\t\t  \t<menu-item>\n\t\t\t\t  \t<name>Template</name>\n\t\t\t\t  \t<icon>/html/skin/image/dotcms/icons/layout_add.gif</icon>\n\t\t\t\t  \t<assoc-portlet>EXT_13</assoc-portlet>\n\t\t\t\t  \t<params>\n\t\t\t\t  \t\t<param>\n\t\t\t\t  \t\t\t<name>struts_action</name>\n\t\t\t\t  \t\t\t<value>/ext/templates/edit_template</value>\n\t\t\t\t  \t\t</param>\n\t\t\t\t  \t</params>\n\t\t\t  \t</menu-item>\n\t\t\t  </submenu>\n\t\t\t</menu-item>\n\t    <!-- Non-New Menu Items-->\n\t  \t<menu-item>\n\t\t  \t<name>Browser</name>\n\t\t  \t<icon>/html/skin/image/dotcms/icons/application_side_list_world.gif</icon>\n\t\t  \t<assoc-portlet></assoc-portlet>\n\t\t  \t<params>\n\t\t  \t\t<param>\n\t\t  \t\t\t<name>struts_action</name>\n\t\t  \t\t\t<value>/ext/browser/view_browser</value>\n\t\t  \t\t</param>\n\t\t  \t</params>\n\t  \t</menu-item>\n\t  \t<menu-item>\n\t\t  \t<name>HTML Pages</name>\n\t\t  \t<icon>/html/skin/image/dotcms/icons/page.gif</icon>\n\t\t  \t<assoc-portlet>EXT_15</assoc-portlet>\n\t\t  \t<params>\n\t\t  \t\t<param>\n\t\t  \t\t\t<name>struts_action</name>\n\t\t  \t\t\t<value>/ext/htmlpages/view_htmlpages</value>\n\t\t  \t\t</param>\n\t\t  \t</params>\n\t  \t</menu-item>\n\t  \t<menu-item>\n\t\t  \t<name>Files</name>\n\t\t  \t<icon>/html/skin/image/dotcms/icons/page_white_stack.gif</icon>\n\t\t  \t<assoc-portlet>EXT_3</assoc-portlet>\n\t\t  \t<params>\n\t\t  \t\t<param>\n\t\t  \t\t\t<name>struts_action</name>\n\t\t  \t\t\t<value>/ext/files/view_files</value>\n\t\t  \t\t</param>\n\t\t  \t</params>\n\t  \t</menu-item>\n\t  \t<menu-item>\n\t\t  \t<name>Containers</name>\n\t\t  \t<icon>/html/skin/image/dotcms/icons/package.gif</icon>\n\t\t  \t<assoc-portlet>EXT_12</assoc-portlet>\n\t\t  \t<params>\n\t\t  \t\t<param>\n\t\t  \t\t\t<name>struts_action</name>\n\t\t  \t\t\t<value>/ext/containers/view_containers</value>\n\t\t  \t\t</param>\n\t\t  \t</params>\n\t  \t</menu-item>\n\t  \t<menu-item>\n\t\t  \t<name>Templates</name>\n\t\t  \t<icon>/html/skin/image/dotcms/icons/layout.gif</icon>\n\t\t  \t<assoc-portlet>EXT_13</assoc-portlet>\n\t\t  \t<params>\n\t\t  \t\t<param>\n\t\t  \t\t\t<name>struts_action</name>\n\t\t  \t\t\t<value>/ext/templates/view_templates</value>\n\t\t  \t\t</param>\n\t\t  \t</params>\n\t  \t</menu-item>\n\t  \t<menu-item>\n\t\t  \t<name>Virtual Links</name>\n\t\t  \t<icon>/html/skin/image/dotcms/icons/server_link.gif</icon>\n\t\t  \t<assoc-portlet>EXT_VIRTUAL_LINKS</assoc-portlet>\n\t\t  \t<params>\n\t\t  \t\t<param>\n\t\t  \t\t\t<name>struts_action</name>\n\t\t  \t\t\t<value>/ext/virtuallinks/view_virtuallinks</value>\n\t\t  \t\t</param>\n\t\t  \t</params>\n\t  \t</menu-item>\n\t  \t<menu-item>\n\t\t  \t<name>Menu Link</name>\n\t\t  \t<icon>/html/skin/image/dotcms/icons/link.gif</icon>\n\t\t  \t<assoc-portlet>EXT_18</assoc-portlet>\n\t\t  \t<params>\n\t\t  \t\t<param>\n\t\t  \t\t\t<name>struts_action</name>\n\t\t  \t\t\t<value>/ext/links/view_links</value>\n\t\t  \t\t</param>\n\t\t  \t</params>\n\t  \t</menu-item>\n   </menu-items>\n  </value> \n </preference>\n</portlet-preferences>	f	CMS Administrator,CMS User,	t
EXT_CMS_MAINTENANCE	SHARED_KEY	dotcms.org	<portlet-preferences>\r\n  <preference>\r\n  <name>MenuItems</name> \r\n  <value>\r\n    <menu-items>\r\n\t\t    <!-- Non-New Menu Items-->\r\n\t\t  \t<menu-item>\r\n\t\t\t  \t<name>Maintenance</name>\r\n\t\t\t  \t<icon>/html/skin/image/dotcms/icons/wrench.gif</icon>\r\n\t\t\t  \t<assoc-portlet>EXT_CMS_MAINTENANCE</assoc-portlet>\r\n\t\t\t  \t<render />\r\n\t\t\t\t  \t<params>\r\n\t\t\t\t  \t\t<param>\r\n\t\t\t\t  \t\t\t<name>struts_action</name>\r\n\t\t\t\t  \t\t\t<value>/ext/cmsmaintenance/view_cms_maintenance</value>\r\n\t\t\t\t  \t\t</param>\r\n\t\t\t\t  \t</params>\r\n\t\t  \t</menu-item>\r\n \t   </menu-items>\r\n    </value> \r\n  </preference>\r\n</portlet-preferences>	t	CMS Administrator,	t
EXT_COMMUNICATIONS_MANAGER	SHARED_KEY	dotcms.org	<portlet-preferences>\n  <preference>\n  <name>MenuItems</name> \n  <value>\n    <menu-items>\n\t\t    <menu-item position="top">\n\t\t    \t<name>New</name>\n\t\t    \t<icon>/html/skin/image/dotcms/icons/page_new.gif</icon>\n\t\t    \t<assoc-portlet>EXT_COMMUNICATIONS_MANAGER</assoc-portlet>\n\t\t    \t<params />\n\t\t    \t<submenu>\n\t\t\t\t  \t<menu-item>\n\t\t\t\t\t  \t<name>Communication</name>\n\t\t\t\t\t  \t<icon>/html/skin/image/dotcms/icons/transmit_blue_page_add.gif</icon>\n\t\t\t\t\t  \t<assoc-portlet>EXT_19</assoc-portlet>\n\t\t\t\t\t  \t<create-campaign />\n\t\t\t\t\t\t  \t<params>\n\t\t\t\t\t\t  \t\t<param>\n\t\t\t\t\t\t  \t\t\t<name>struts_action</name>\n\t\t\t\t\t\t  \t\t\t<value>/ext/communications/edit_communication</value>\n\t\t\t\t\t\t  \t\t</param>\n\t\t\t\t\t\t  \t\t<param>\n\t\t\t\t\t\t  \t\t\t<name>cmd</name>\n\t\t\t\t\t\t  \t\t\t<value>edit</value>\n\t\t\t\t\t\t  \t\t</param>\n\t\t\t\t\t\t  \t</params>\n\t\t\t\t  \t</menu-item>\n\t\t    \t</submenu>\n\t\t    </menu-item>\n\t\t    <!-- Non-New Menu Items-->\n\t\t  \t<menu-item>\n\t\t\t  \t<name>Communications</name>\n\t\t\t  \t<icon>/html/skin/image/dotcms/icons/transmit_blue_page.gif</icon>\n\t\t\t  \t<assoc-portlet>EXT_COMMUNICATIONS_MANAGER</assoc-portlet>\n\t\t\t\t  \t<params>\n\t\t\t\t  \t\t<param>\n\t\t\t\t  \t\t\t<name>struts_action</name>\n\t\t\t\t  \t\t\t<value>/ext/communications/view_communications</value>\n\t\t\t\t  \t\t</param>\n\t\t\t\t  \t</params>\n\t\t  \t</menu-item>\n    \t</menu-items>\n    </value> \n  </preference>\n</portlet-preferences>	f	Campaign Manager Admin,Campaign Manager Editor,	t
EXT_LANG	SHARED_KEY	dotcms.org	<portlet-preferences>\r\n  <preference>\r\n  <name>MenuItems</name> \r\n  <value>\r\n    <menu-items>\r\n\t\t    <!-- New Menu Items-->\r\n\t\t    <menu-item position="top">\r\n\t\t    \t<name>New</name>\r\n\t\t    \t<icon>/html/skin/image/dotcms/icons/page_new.gif</icon>\r\n\t\t    \t<assoc-portlet>EXT_LANG</assoc-portlet>\r\n\t\t    \t<params />\r\n\t\t    \t<submenu>\r\n\t\t\t\t  \t<menu-item>\r\n\t\t\t\t\t  \t<name>Dictionary Term</name>\r\n\t\t\t\t\t  \t<icon>/html/skin/image/dotcms/icons/book_open_add.gif</icon>\r\n\t\t\t\t\t  \t<assoc-portlet>EXT_LANG</assoc-portlet>\r\n\t\t\t\t\t  \t<params>\r\n\t\t\t\t\t  \t\t<param>\r\n\t\t\t\t\t  \t\t\t<name>struts_action</name>\r\n\t\t\t\t\t  \t\t\t<value>/ext/languages_manager/edit_languages</value>\r\n\t\t\t\t\t  \t\t</param>\r\n\t\t\t\t\t  \t\t<param>\r\n\t\t\t\t\t  \t\t\t<name>id</name>\r\n\t\t\t\t\t  \t\t\t<value></value>\r\n\t\t\t\t\t  \t\t</param>\r\n\t\t\t\t\t  \t</params>\r\n\t\t\t\t  \t</menu-item>\r\n\t\t\t\t  </submenu>\r\n\t\t  \t</menu-item>\r\n\t\t    <!-- Non-New Menu Items-->\r\n\t\t  \t<menu-item>\r\n\t\t\t  \t<name>Dictionaries</name>\r\n\t\t\t  \t<icon>/html/skin/image/dotcms/icons/book.gif</icon>\r\n\t\t\t  \t<assoc-portlet>EXT_LANG</assoc-portlet>\r\n\t\t\t  \t<params>\r\n\t\t\t  \t\t<param>\r\n\t\t\t  \t\t\t<name>struts_action</name>\r\n\t\t\t  \t\t\t<value>/ext/languages_manager/view_languages_manager</value>\r\n\t\t\t  \t\t</param>\r\n\t\t\t  \t</params>\r\n\t\t  \t</menu-item>\r\n\t    </menu-items>\r\n    </value> \r\n  </preference>\r\n</portlet-preferences>	t	CMS Administrator,	t
EXT_REPORTMANAGER	SHARED_KEY	dotcms.org	<portlet-preferences>\r\n  <preference>\r\n  <name>MenuItems</name> \r\n  <value>\r\n    <menu-items>\r\n\t\t    <!-- New Menu Items-->\r\n\t\t    <menu-item position="top">\r\n\t\t    \t<name>New</name>\r\n\t\t    \t<icon>/html/skin/image/dotcms/icons/page_new.gif</icon>\r\n\t\t    \t<assoc-portlet>EXT_REPORTMANAGER</assoc-portlet>\r\n\t\t    \t<create-report />\r\n\t\t    \t<params />\r\n\t\t    \t<submenu>\r\n\t\t\t\t  \t<menu-item>\r\n\t\t\t\t\t  \t<name>Report</name>\r\n\t\t\t\t\t  \t<icon>/html/skin/image/dotcms/icons/report_add.gif</icon>\r\n\t\t\t\t\t  \t<assoc-portlet>EXT_REPORTMANAGER</assoc-portlet>\r\n\t\t\t\t\t  \t<params>\r\n\t\t\t\t\t  \t\t<param>\r\n\t\t\t\t\t  \t\t\t<name>struts_action</name>\r\n\t\t\t\t\t  \t\t\t<value>/ext/report/edit_report</value>\r\n\t\t\t\t\t  \t\t</param>\r\n\t\t\t\t\t  \t</params>\r\n\t\t\t\t  \t</menu-item>\r\n\t\t    \t</submenu>\r\n\t\t    </menu-item>\r\n\t\t    <!-- Non-New Menu Items-->\r\n\t\t  \t<menu-item>\r\n\t\t\t  \t<name>Reports</name>\r\n\t\t\t  \t<icon>/html/skin/image/dotcms/icons/report.gif</icon>\r\n\t\t\t  \t<assoc-portlet>EXT_REPORTMANAGER</assoc-portlet>\r\n\t\t\t  \t<show-reports />\r\n\t\t\t\t  \t<params>\r\n\t\t\t\t  \t\t<param>\r\n\t\t\t\t  \t\t\t<name>struts_action</name>\r\n\t\t\t\t  \t\t\t<value>/ext/report/view_reports</value>\r\n\t\t\t\t  \t\t</param>\r\n\t\t\t\t  \t</params>\r\n\t\t  \t</menu-item>\r\n\t    </menu-items>\r\n    </value> \r\n  </preference>\r\n</portlet-preferences>	f	CMS Administrator,Report Administrator,Report Editor,Report Viewer,	t
EXT_STRUCTURE	SHARED_KEY	dotcms.org	<portlet-preferences>\r\n  <preference>\r\n  <name>MenuItems</name> \r\n  <value>\r\n    <menu-items>\r\n\t    <!-- New Menu Items-->\r\n\t\t    <menu-item position="top">\r\n\t\t    \t<name>New</name>\r\n\t\t    \t<icon>/html/skin/image/dotcms/icons/page_new.gif</icon>\r\n\t\t    \t<assoc-portlet />\r\n\t\t    \t<params />\r\n\t\t    \t<submenu>\r\n\t\t\t\t  \t<menu-item>\r\n\t\t\t\t\t  \t<name>Structure</name>\r\n\t\t\t\t\t  \t<icon>/html/skin/image/dotcms/icons/table_add.gif</icon>\r\n\t\t\t\t\t  \t<assoc-portlet>EXT_STRUCTURE</assoc-portlet>\r\n\t\t\t\t\t  \t<params>\r\n\t\t\t\t\t  \t\t<param>\r\n\t\t\t\t\t  \t\t\t<name>struts_action</name>\r\n\t\t\t\t\t  \t\t\t<value>/ext/structure/edit_structure</value>\r\n\t\t\t\t\t  \t\t</param>\r\n\t\t\t\t\t  \t</params>\r\n\t\t\t\t  \t</menu-item>\r\n\t\t\t\t  \t<menu-item>\r\n\t\t\t\t\t  \t<name>Relationship</name>\r\n\t\t\t\t\t  \t<icon>/html/skin/image/dotcms/icons/table_relationship_add.gif</icon>\r\n\t\t\t\t\t  \t<assoc-portlet>EXT_STRUCTURE</assoc-portlet>\r\n\t\t\t\t\t  \t<params>\r\n\t\t\t\t\t  \t\t<param>\r\n\t\t\t\t\t  \t\t\t<name>struts_action</name>\r\n\t\t\t\t\t  \t\t\t<value>/ext/structure/edit_relationship</value>\r\n\t\t\t\t\t  \t\t</param>\r\n\t\t\t\t\t  \t</params>\r\n\t\t\t\t  \t</menu-item>\r\n\t\t    \t</submenu>\r\n\t\t    </menu-item>\r\n\t\t    <!-- Non-New Menu Items-->\r\n\t\t  \t<menu-item>\r\n\t\t\t  \t<name>Structures</name>\r\n\t\t\t  \t<icon>/html/skin/image/dotcms/icons/table_multiple.gif</icon>\r\n\t\t\t  \t<assoc-portlet>EXT_STRUCTURE</assoc-portlet>\r\n\t\t\t  \t<params>\r\n\t\t\t  \t\t<param>\r\n\t\t\t  \t\t\t<name>struts_action</name>\r\n\t\t\t  \t\t\t<value>/ext/structure/view_structure</value>\r\n\t\t\t  \t\t</param>\r\n\t\t\t  \t</params>\r\n\t\t  \t</menu-item>\r\n\t\t  \t<menu-item>\r\n\t\t\t  \t<name>Relationships</name>\r\n\t\t\t  \t<icon>/html/skin/image/dotcms/icons/table_relationship.gif</icon>\r\n\t\t\t  \t<assoc-portlet>EXT_STRUCTURE</assoc-portlet>\r\n\t\t\t  \t<params>\r\n\t\t\t  \t\t<param>\r\n\t\t\t  \t\t\t<name>struts_action</name>\r\n\t\t\t  \t\t\t<value>/ext/structure/view_relationships</value>\r\n\t\t\t  \t\t</param>\r\n\t\t\t  \t</params>\r\n\t\t  \t</menu-item>\r\n\t    </menu-items>\r\n    </value> \r\n  </preference>\r\n</portlet-preferences>	f	CMS Administrator,	t
EXT_USERMANAGER	SHARED_KEY	dotcms.org	<portlet-preferences>\r\n  <preference>\r\n  <name>MenuItems</name> \r\n  <value>\r\n    <menu-items>\r\n\t\t    <!-- New Menu Items-->\r\n\t\t    <menu-item position="top">\r\n\t\t    \t<name>New</name>\r\n\t\t    \t<icon>/html/skin/image/dotcms/icons/page_new.gif</icon>\r\n\t\t    \t<assoc-portlet>EXT_USERMANAGER</assoc-portlet>\r\n\t\t    \t<params />\r\n\t\t    \t<submenu>\r\n\t\t\t\t  \t<menu-item>\r\n\t\t\t\t\t  \t<name>User</name>\r\n\t\t\t\t\t  \t<icon>/html/skin/image/dotcms/icons/user_add.gif</icon>\r\n\t\t\t\t\t  \t<assoc-portlet>EXT_USERMANAGER</assoc-portlet>\r\n\t\t\t\t\t\t  \t<params>\r\n\t\t\t\t\t\t  \t\t<param>\r\n\t\t\t\t\t\t  \t\t\t<name>struts_action</name>\r\n\t\t\t\t\t\t  \t\t\t<value>/ext/usermanager/edit_usermanager</value>\r\n\t\t\t\t\t\t  \t\t</param>\r\n\t\t\t\t\t\t  \t\t<param>\r\n\t\t\t\t\t\t  \t\t\t<name>cmd</name>\r\n\t\t\t\t\t\t  \t\t\t<value>load_register_user</value>\r\n\t\t\t\t\t\t  \t\t</param>\r\n\t\t\t\t\t\t  \t</params>\r\n\t\t\t\t  \t</menu-item>\r\n\t\t    \t</submenu>\r\n\t\t    </menu-item>\r\n\t\t    <!-- Non-New Menu Items-->\r\n\t\t  \t<menu-item>\r\n\t\t\t  \t<name>Users</name>\r\n\t\t\t  \t<icon>/html/skin/image/dotcms/icons/user.gif</icon>\r\n\t\t\t  \t<assoc-portlet>EXT_USERMANAGER</assoc-portlet>\r\n\t\t\t\t  \t<params>\r\n\t\t\t\t  \t\t<param>\r\n\t\t\t\t  \t\t\t<name>struts_action</name>\r\n\t\t\t\t  \t\t\t<value>/ext/usermanager/view_usermanagerlist</value>\r\n\t\t\t\t  \t\t</param>\r\n\t\t\t\t  \t</params>\r\n\t\t  \t</menu-item>\r\n\t    </menu-items>\r\n    </value> \r\n  </preference>\r\n</portlet-preferences>	f	Mailing Lists Administrator,User Manager Administrator,User Manager Editor,	t
EXT_VIRTUAL_LINKS	SHARED_KEY	dotcms.org	<portlet-preferences>\r\n  <preference>\r\n  <name>MenuItems</name> \r\n  <value>\r\n    <menu-items>\r\n\t\t    <!-- Non-New Menu Items-->\r\n\t\t  \t<menu-item>\r\n\t\t\t  \t<name>Virtual Links</name>\r\n\t\t\t  \t<icon>/html/skin/image/dotcms/icons/server_link.gif</icon>\r\n\t\t\t  \t<assoc-portlet>EXT_VIRTUAL_LINKS</assoc-portlet>\r\n\t\t\t\t  \t<params>\r\n\t\t\t\t  \t\t<param>\r\n\t\t\t\t  \t\t\t<name>struts_action</name>\r\n\t\t\t\t  \t\t\t<value>/ext/virtuallinks/view_virtuallinks</value>\r\n\t\t\t\t  \t\t</param>\r\n\t\t\t\t  \t</params>\r\n\t\t  \t</menu-item>\r\n    \t</menu-items>\r\n    </value> \r\n  </preference>\r\n</portlet-preferences>	f	Administrator,Power User,	t
EXT_WEBFORMS	SHARED_KEY	dotcms.org	<portlet-preferences>\r\n  <preference>\r\n  <name>MenuItems</name> \r\n  <value>\r\n    <menu-items>\r\n\t\t    <!-- Non-New Menu Items-->\r\n\t\t  \t<menu-item>\r\n\t\t\t  \t<name>Web Forms</name>\r\n\t\t\t  \t<icon>/html/skin/image/dotcms/icons/application_form.gif</icon>\r\n\t\t\t  \t<assoc-portlet>EXT_WEBFORMS</assoc-portlet>\r\n\t\t\t  \t<show-webforms />\r\n\t\t\t\t  \t<params>\r\n\t\t\t\t  \t\t<param>\r\n\t\t\t\t  \t\t\t<name>struts_action</name>\r\n\t\t\t\t  \t\t\t<value>/ext/webforms/view_webforms</value>\r\n\t\t\t\t  \t\t</param>\r\n\t\t\t\t  \t</params>\r\n\t\t  \t</menu-item>\r\n    \t</menu-items>\r\n    </value> \r\n  </preference>\r\n</portlet-preferences>	t	CMS Administrator,	t
c_Personas	SHARED_KEY	dotcms.org	<?xml version="1.0" encoding="UTF-8"?>\r\n<portlet><portlet-name>c_Personas</portlet-name><portlet-class>com.liferay.portlet.StrutsPortlet</portlet-class><resource-bundle>com.liferay.portlet.StrutsResourceBundle</resource-bundle><init-param><name>name</name><value>Personas</value></init-param><init-param><name>baseTypes</name><value>PERSONA</value></init-param><init-param><name>view-action</name><value>/ext/contentlet/view_contentlets</value></init-param><init-param><name>portletSource</name><value>db</value></init-param><init-param><name>contentTypes</name><value></value></init-param></portlet>\r\n	f		t
c_Widgets	SHARED_KEY	dotcms.org	<?xml version="1.0" encoding="UTF-8"?>\r\n<portlet><portlet-name>c_Widgets</portlet-name><portlet-class>com.liferay.portlet.StrutsPortlet</portlet-class><resource-bundle>com.liferay.portlet.StrutsResourceBundle</resource-bundle><init-param><name>name</name><value>Widgets</value></init-param><init-param><name>baseTypes</name><value>WIDGET</value></init-param><init-param><name>view-action</name><value>/ext/contentlet/view_contentlets</value></init-param><init-param><name>portletSource</name><value>db</value></init-param><init-param><name>contentTypes</name><value></value></init-param></portlet>\r\n	f		t
c_Search-All	SHARED_KEY	dotcms.org	<?xml version="1.0" encoding="UTF-8"?>\r\n<portlet><portlet-name>c_Search-All</portlet-name><portlet-class>com.liferay.portlet.StrutsPortlet</portlet-class><resource-bundle>com.liferay.portlet.StrutsResourceBundle</resource-bundle><init-param><name>name</name><value>Search All</value></init-param><init-param><name>baseTypes</name><value>CONTENT,WIDGET,FILEASSET,KEY_VALUE</value></init-param><init-param><name>view-action</name><value>/ext/contentlet/view_contentlets</value></init-param><init-param><name>portletSource</name><value>db</value></init-param><init-param><name>contentTypes</name><value></value></init-param></portlet>\r\n	f		t
c_Call-To-Actions	SHARED_KEY	dotcms.org	<?xml version="1.0" encoding="UTF-8"?>\r\n<portlet><portlet-name>c_Call-To-Actions</portlet-name><portlet-class>com.liferay.portlet.StrutsPortlet</portlet-class><resource-bundle>com.liferay.portlet.StrutsResourceBundle</resource-bundle><init-param><name>name</name><value>Call To Actions</value></init-param><init-param><name>baseTypes</name><value></value></init-param><init-param><name>view-action</name><value>/ext/contentlet/view_contentlets</value></init-param><init-param><name>portletSource</name><value>db</value></init-param><init-param><name>contentTypes</name><value>CallToAction</value></init-param></portlet>\r\n	f		t
c_Events	SHARED_KEY	dotcms.org	<?xml version="1.0" encoding="UTF-8"?>\r\n<portlet><portlet-name>c_Events</portlet-name><portlet-class>com.liferay.portlet.StrutsPortlet</portlet-class><resource-bundle>com.liferay.portlet.StrutsResourceBundle</resource-bundle><init-param><name>name</name><value>Events</value></init-param><init-param><name>baseTypes</name><value></value></init-param><init-param><name>view-action</name><value>/ext/contentlet/view_contentlets</value></init-param><init-param><name>portletSource</name><value>db</value></init-param><init-param><name>contentTypes</name><value>calendarEvent</value></init-param></portlet>\r\n	f		t
c_Rich-Text	SHARED_KEY	dotcms.org	<?xml version="1.0" encoding="UTF-8"?>\r\n<portlet><portlet-name>c_Rich-Text</portlet-name><portlet-class>com.liferay.portlet.StrutsPortlet</portlet-class><resource-bundle>com.liferay.portlet.StrutsResourceBundle</resource-bundle><init-param><name>name</name><value>Rich Text</value></init-param><init-param><name>baseTypes</name><value></value></init-param><init-param><name>view-action</name><value>/ext/contentlet/view_contentlets</value></init-param><init-param><name>portletSource</name><value>db</value></init-param><init-param><name>contentTypes</name><value>webPageContent</value></init-param></portlet>\r\n	f		t
c_Product-Line	SHARED_KEY	dotcms.org	<?xml version="1.0" encoding="UTF-8"?>\r\n<portlet><portlet-name>c_Product-Line</portlet-name><portlet-class>com.liferay.portlet.StrutsPortlet</portlet-class><resource-bundle>com.liferay.portlet.StrutsResourceBundle</resource-bundle><init-param><name>name</name><value>Product Line</value></init-param><init-param><name>baseTypes</name><value></value></init-param><init-param><name>view-action</name><value>/ext/contentlet/view_contentlets</value></init-param><init-param><name>portletSource</name><value>db</value></init-param><init-param><name>contentTypes</name><value>ProductLineLandingPage</value></init-param></portlet>\r\n	f		t
dotTools		dotcms.org	<?xml version="1.0" encoding="UTF-8"?>\r\n<portlet><portlet-name>dotTools</portlet-name><portlet-class>com.liferay.portlet.JSPPortlet</portlet-class><resource-bundle>com.liferay.portlet.StrutsResourceBundle</resource-bundle><init-param><name>view-jsp</name><value>/osgi/dotTools-osgi-0.1/dottools/launcher.jsp</value></init-param></portlet>\r\n	f	\N	t
\.


--
-- Data for Name: portletpreferences; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.portletpreferences (portletid, userid, layoutid, preferences) FROM stdin;
\.


--
-- Data for Name: publishing_bundle; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.publishing_bundle (id, name, publish_date, expire_date, owner, force_push) FROM stdin;
\.


--
-- Data for Name: publishing_bundle_environment; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.publishing_bundle_environment (id, bundle_id, environment_id) FROM stdin;
\.


--
-- Data for Name: publishing_end_point; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.publishing_end_point (id, group_id, server_name, address, port, protocol, enabled, auth_key, sending) FROM stdin;
\.


--
-- Data for Name: publishing_environment; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.publishing_environment (id, name, push_to_all) FROM stdin;
\.


--
-- Data for Name: publishing_pushed_assets; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.publishing_pushed_assets (bundle_id, asset_id, asset_type, push_date, environment_id, endpoint_ids, publisher) FROM stdin;
\.


--
-- Data for Name: publishing_queue; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.publishing_queue (id, operation, asset, language_id, entered_date, publish_date, type, bundle_id) FROM stdin;
\.


--
-- Data for Name: publishing_queue_audit; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.publishing_queue_audit (bundle_id, status, status_pojo, status_updated, create_date) FROM stdin;
\.


--
-- Name: publishing_queue_id_seq; Type: SEQUENCE SET; Schema: public; Owner: dotcms_dev
--

SELECT pg_catalog.setval('public.publishing_queue_id_seq', 1, false);


--
-- Data for Name: qrtz_blob_triggers; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.qrtz_blob_triggers (trigger_name, trigger_group, blob_data) FROM stdin;
\.


--
-- Data for Name: qrtz_calendars; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.qrtz_calendars (calendar_name, calendar) FROM stdin;
\.


--
-- Data for Name: qrtz_cron_triggers; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.qrtz_cron_triggers (trigger_name, trigger_group, cron_expression, time_zone_id) FROM stdin;
\.


--
-- Data for Name: qrtz_excl_blob_triggers; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.qrtz_excl_blob_triggers (trigger_name, trigger_group, blob_data) FROM stdin;
\.


--
-- Data for Name: qrtz_excl_calendars; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.qrtz_excl_calendars (calendar_name, calendar) FROM stdin;
\.


--
-- Data for Name: qrtz_excl_cron_triggers; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.qrtz_excl_cron_triggers (trigger_name, trigger_group, cron_expression, time_zone_id) FROM stdin;
trigger10	group10	0 0 12 * * ?	America/New_York
trigger20	group20	0 0 0/2 * * ?	America/New_York
trigger11	group11	0 0 12 * * ?	America/New_York
trigger12	group12	0 0 0/1 * * ?	America/New_York
trigger15	group15	0 0 1 * * ?	America/New_York
trigger18	group18	0 0 3 * * ?	America/New_York
trigger26	group26	0 0 0 1/1 * ? *	America/New_York
trigger28	group28	0 0 0 1/3 * ? *	America/New_York
trigger25	group25	0 0/1 * * * ?	America/New_York
trigger19	group19	0 0/1 * * * ?	America/New_York
trigger24	group24	0/30 * * * * ?	America/New_York
\.


--
-- Data for Name: qrtz_excl_fired_triggers; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.qrtz_excl_fired_triggers (entry_id, trigger_name, trigger_group, is_volatile, instance_name, fired_time, priority, state, job_name, job_group, is_stateful, requests_recovery) FROM stdin;
\.


--
-- Data for Name: qrtz_excl_job_details; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.qrtz_excl_job_details (job_name, job_group, description, job_class_name, is_durable, is_volatile, is_stateful, requests_recovery, job_data) FROM stdin;
WebDavCleanupJob	dotcms_jobs	\N	com.dotmarketing.quartz.job.WebDavCleanupJob	f	f	f	f	\\xaced0005737200156f72672e71756172747a2e4a6f62446174614d61709fb083e8bfa9b0cb020000787200266f72672e71756172747a2e7574696c732e537472696e674b65794469727479466c61674d61708208e8c3fbc55d280200015a0013616c6c6f77735472616e7369656e74446174617872001d6f72672e71756172747a2e7574696c732e4469727479466c61674d617013e62ead28760ace0200025a000564697274794c00036d617074000f4c6a6176612f7574696c2f4d61703b787000737200116a6176612e7574696c2e486173684d61700507dac1c31660d103000246000a6c6f6164466163746f724900097468726573686f6c6478703f40000000000010770800000010000000007800
BinaryCleanupJob	dotcms_jobs	\N	com.dotmarketing.quartz.job.BinaryCleanupJob	f	f	t	f	\\xaced0005737200156f72672e71756172747a2e4a6f62446174614d61709fb083e8bfa9b0cb020000787200266f72672e71756172747a2e7574696c732e537472696e674b65794469727479466c61674d61708208e8c3fbc55d280200015a0013616c6c6f77735472616e7369656e74446174617872001d6f72672e71756172747a2e7574696c732e4469727479466c61674d617013e62ead28760ace0200025a000564697274794c00036d617074000f4c6a6176612f7574696c2f4d61703b787000737200116a6176612e7574696c2e486173684d61700507dac1c31660d103000246000a6c6f6164466163746f724900097468726573686f6c6478703f40000000000010770800000010000000007800
TrashCleanupJob	dotcms_jobs	\N	com.dotmarketing.quartz.job.TrashCleanupJob	f	f	f	f	\\xaced0005737200156f72672e71756172747a2e4a6f62446174614d61709fb083e8bfa9b0cb020000787200266f72672e71756172747a2e7574696c732e537472696e674b65794469727479466c61674d61708208e8c3fbc55d280200015a0013616c6c6f77735472616e7369656e74446174617872001d6f72672e71756172747a2e7574696c732e4469727479466c61674d617013e62ead28760ace0200025a000564697274794c00036d617074000f4c6a6176612f7574696c2f4d61703b787000737200116a6176612e7574696c2e486173684d61700507dac1c31660d103000246000a6c6f6164466163746f724900097468726573686f6c6478703f40000000000010770800000010000000007800
DashboardJobImpl	dotcms_jobs	\N	com.dotcms.enterprise.priv.DashboardJobImpl	f	f	t	f	\\xaced0005737200156f72672e71756172747a2e4a6f62446174614d61709fb083e8bfa9b0cb020000787200266f72672e71756172747a2e7574696c732e537472696e674b65794469727479466c61674d61708208e8c3fbc55d280200015a0013616c6c6f77735472616e7369656e74446174617872001d6f72672e71756172747a2e7574696c732e4469727479466c61674d617013e62ead28760ace0200025a000564697274794c00036d617074000f4c6a6176612f7574696c2f4d61703b787000737200116a6176612e7574696c2e486173684d61700507dac1c31660d103000246000a6c6f6164466163746f724900097468726573686f6c6478703f40000000000010770800000010000000007800
DeleteOldClickstreams	dotcms_jobs	\N	com.dotmarketing.quartz.job.DeleteOldClickstreams	f	f	t	f	\\xaced0005737200156f72672e71756172747a2e4a6f62446174614d61709fb083e8bfa9b0cb020000787200266f72672e71756172747a2e7574696c732e537472696e674b65794469727479466c61674d61708208e8c3fbc55d280200015a0013616c6c6f77735472616e7369656e74446174617872001d6f72672e71756172747a2e7574696c732e4469727479466c61674d617013e62ead28760ace0200025a000564697274794c00036d617074000f4c6a6176612f7574696c2f4d61703b787000737200116a6176612e7574696c2e486173684d61700507dac1c31660d103000246000a6c6f6164466163746f724900097468726573686f6c6478703f40000000000010770800000010000000007800
PublishQueueJob	dotcms_jobs	\N	com.dotcms.publisher.business.PublisherQueueJob	f	f	t	f	\\xaced0005737200156f72672e71756172747a2e4a6f62446174614d61709fb083e8bfa9b0cb020000787200266f72672e71756172747a2e7574696c732e537472696e674b65794469727479466c61674d61708208e8c3fbc55d280200015a0013616c6c6f77735472616e7369656e74446174617872001d6f72672e71756172747a2e7574696c732e4469727479466c61674d617013e62ead28760ace0200025a000564697274794c00036d617074000f4c6a6176612f7574696c2f4d61703b787000737200116a6176612e7574696c2e486173684d61700507dac1c31660d103000246000a6c6f6164466163746f724900097468726573686f6c6478703f40000000000010770800000010000000007800
linkchecker	dotcms_jobs	\N	com.dotcms.enterprise.linkchecker.LinkCheckerJob	f	f	t	f	\\xaced0005737200156f72672e71756172747a2e4a6f62446174614d61709fb083e8bfa9b0cb020000787200266f72672e71756172747a2e7574696c732e537472696e674b65794469727479466c61674d61708208e8c3fbc55d280200015a0013616c6c6f77735472616e7369656e74446174617872001d6f72672e71756172747a2e7574696c732e4469727479466c61674d617013e62ead28760ace0200025a000564697274794c00036d617074000f4c6a6176612f7574696c2f4d61703b787000737200116a6176612e7574696c2e486173684d61700507dac1c31660d103000246000a6c6f6164466163746f724900097468726573686f6c6478703f40000000000010770800000010000000007800
EscalationThreadJob	dotcms_jobs	\N	com.dotcms.workflow.EscalationThread	f	f	t	f	\\xaced0005737200156f72672e71756172747a2e4a6f62446174614d61709fb083e8bfa9b0cb020000787200266f72672e71756172747a2e7574696c732e537472696e674b65794469727479466c61674d61708208e8c3fbc55d280200015a0013616c6c6f77735472616e7369656e74446174617872001d6f72672e71756172747a2e7574696c732e4469727479466c61674d617013e62ead28760ace0200025a000564697274794c00036d617074000f4c6a6176612f7574696c2f4d61703b787000737200116a6176612e7574696c2e486173684d61700507dac1c31660d103000246000a6c6f6164466163746f724900097468726573686f6c6478703f40000000000010770800000010000000007800
FreeServerFromClusterJob	dotcms_jobs	\N	com.dotmarketing.quartz.job.FreeServerFromClusterJob	f	f	t	f	\\xaced0005737200156f72672e71756172747a2e4a6f62446174614d61709fb083e8bfa9b0cb020000787200266f72672e71756172747a2e7574696c732e537472696e674b65794469727479466c61674d61708208e8c3fbc55d280200015a0013616c6c6f77735472616e7369656e74446174617872001d6f72672e71756172747a2e7574696c732e4469727479466c61674d617013e62ead28760ace0200025a000564697274794c00036d617074000f4c6a6176612f7574696c2f4d61703b787000737200116a6176612e7574696c2e486173684d61700507dac1c31660d103000246000a6c6f6164466163746f724900097468726573686f6c6478703f40000000000010770800000010000000007800
CleanUnDeletedUsersJob	dotcms_jobs	\N	com.dotmarketing.quartz.job.CleanUnDeletedUsersJob	f	f	t	f	\\xaced0005737200156f72672e71756172747a2e4a6f62446174614d61709fb083e8bfa9b0cb020000787200266f72672e71756172747a2e7574696c732e537472696e674b65794469727479466c61674d61708208e8c3fbc55d280200015a0013616c6c6f77735472616e7369656e74446174617872001d6f72672e71756172747a2e7574696c732e4469727479466c61674d617013e62ead28760ace0200025a000564697274794c00036d617074000f4c6a6176612f7574696c2f4d61703b787000737200116a6176612e7574696c2e486173684d61700507dac1c31660d103000246000a6c6f6164466163746f724900097468726573686f6c6478703f40000000000010770800000010000000007800
DeleteOldSystemEventsJob	dotcms_jobs	\N	com.dotcms.job.system.event.DeleteOldSystemEventsJob	f	f	f	f	\\xaced0005737200156f72672e71756172747a2e4a6f62446174614d61709fb083e8bfa9b0cb020000787200266f72672e71756172747a2e7574696c732e537472696e674b65794469727479466c61674d61708208e8c3fbc55d280200015a0013616c6c6f77735472616e7369656e74446174617872001d6f72672e71756172747a2e7574696c732e4469727479466c61674d617013e62ead28760ace0200025a000564697274794c00036d617074000f4c6a6176612f7574696c2f4d61703b787000737200116a6176612e7574696c2e486173684d61700507dac1c31660d103000246000a6c6f6164466163746f724900097468726573686f6c6478703f40000000000010770800000010000000007800
\.


--
-- Data for Name: qrtz_excl_job_listeners; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.qrtz_excl_job_listeners (job_name, job_group, job_listener) FROM stdin;
\.


--
-- Data for Name: qrtz_excl_locks; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.qrtz_excl_locks (lock_name) FROM stdin;
TRIGGER_ACCESS
JOB_ACCESS
CALENDAR_ACCESS
STATE_ACCESS
MISFIRE_ACCESS
\.


--
-- Data for Name: qrtz_excl_paused_trigger_grps; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.qrtz_excl_paused_trigger_grps (trigger_group) FROM stdin;
\.


--
-- Data for Name: qrtz_excl_scheduler_state; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.qrtz_excl_scheduler_state (instance_name, last_checkin_time, checkin_interval) FROM stdin;
e64a5620-9bd4-4e08-a53a-67a80079eea1	1585199612954	20000
\.


--
-- Data for Name: qrtz_excl_simple_triggers; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.qrtz_excl_simple_triggers (trigger_name, trigger_group, repeat_count, repeat_interval, times_triggered) FROM stdin;
\.


--
-- Data for Name: qrtz_excl_trigger_listeners; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.qrtz_excl_trigger_listeners (trigger_name, trigger_group, trigger_listener) FROM stdin;
\.


--
-- Data for Name: qrtz_excl_triggers; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.qrtz_excl_triggers (trigger_name, trigger_group, job_name, job_group, is_volatile, description, next_fire_time, prev_fire_time, priority, trigger_state, trigger_type, start_time, end_time, calendar_name, misfire_instr, job_data) FROM stdin;
trigger10	group10	WebDavCleanupJob	dotcms_jobs	f	\N	1585238400000	-1	5	WAITING	CRON	1585197371000	0	\N	1	\\x
trigger24	group24	EscalationThreadJob	dotcms_jobs	f	\N	1585199640000	1585199610000	5	WAITING	CRON	1585199292000	0	\N	1	\\x
trigger19	group19	PublishQueueJob	dotcms_jobs	f	\N	1585199640000	1585199580000	5	WAITING	CRON	1585199292000	0	\N	1	\\x
trigger20	group20	linkchecker	dotcms_jobs	f	\N	1585202400000	-1	5	WAITING	CRON	1585197371000	0	\N	2	\\x
trigger25	group25	FreeServerFromClusterJob	dotcms_jobs	f	\N	1585199640000	1585199580000	5	WAITING	CRON	1585199292000	0	\N	1	\\x
trigger11	group11	BinaryCleanupJob	dotcms_jobs	f	\N	1585238400000	-1	5	WAITING	CRON	1585199292000	0	\N	1	\\x
trigger12	group12	TrashCleanupJob	dotcms_jobs	f	\N	1585202400000	-1	5	WAITING	CRON	1585199292000	0	\N	1	\\x
trigger15	group15	DashboardJobImpl	dotcms_jobs	f	\N	1585285200000	-1	5	WAITING	CRON	1585199292000	0	\N	1	\\x
trigger18	group18	DeleteOldClickstreams	dotcms_jobs	f	\N	1585206000000	-1	5	WAITING	CRON	1585199292000	0	\N	1	\\x
trigger26	group26	CleanUnDeletedUsersJob	dotcms_jobs	f	\N	1585281600000	-1	5	WAITING	CRON	1585199292000	0	\N	1	\\x
trigger28	group28	DeleteOldSystemEventsJob	dotcms_jobs	f	\N	1585368000000	-1	5	WAITING	CRON	1585199292000	0	\N	1	\\x
\.


--
-- Data for Name: qrtz_fired_triggers; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.qrtz_fired_triggers (entry_id, trigger_name, trigger_group, is_volatile, instance_name, fired_time, priority, state, job_name, job_group, is_stateful, requests_recovery) FROM stdin;
\.


--
-- Data for Name: qrtz_job_details; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.qrtz_job_details (job_name, job_group, description, job_class_name, is_durable, is_volatile, is_stateful, requests_recovery, job_data) FROM stdin;
\.


--
-- Data for Name: qrtz_job_listeners; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.qrtz_job_listeners (job_name, job_group, job_listener) FROM stdin;
\.


--
-- Data for Name: qrtz_locks; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.qrtz_locks (lock_name) FROM stdin;
TRIGGER_ACCESS
JOB_ACCESS
CALENDAR_ACCESS
STATE_ACCESS
MISFIRE_ACCESS
\.


--
-- Data for Name: qrtz_paused_trigger_grps; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.qrtz_paused_trigger_grps (trigger_group) FROM stdin;
\.


--
-- Data for Name: qrtz_scheduler_state; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.qrtz_scheduler_state (instance_name, last_checkin_time, checkin_interval) FROM stdin;
\.


--
-- Data for Name: qrtz_simple_triggers; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.qrtz_simple_triggers (trigger_name, trigger_group, repeat_count, repeat_interval, times_triggered) FROM stdin;
\.


--
-- Data for Name: qrtz_trigger_listeners; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.qrtz_trigger_listeners (trigger_name, trigger_group, trigger_listener) FROM stdin;
\.


--
-- Data for Name: qrtz_triggers; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.qrtz_triggers (trigger_name, trigger_group, job_name, job_group, is_volatile, description, next_fire_time, prev_fire_time, priority, trigger_state, trigger_type, start_time, end_time, calendar_name, misfire_instr, job_data) FROM stdin;
\.


--
-- Data for Name: quartz_log; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.quartz_log (id, job_name, serverid, time_started) FROM stdin;
\.


--
-- Name: quartz_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: dotcms_dev
--

SELECT pg_catalog.setval('public.quartz_log_id_seq', 1, false);


--
-- Data for Name: recipient; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.recipient (inode, name, lastname, email, sent, opened, last_result, last_message, user_id) FROM stdin;
\.


--
-- Data for Name: relationship; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.relationship (inode, parent_structure_inode, child_structure_inode, parent_relation_name, child_relation_name, relation_type_value, cardinality, parent_required, child_required, fixed) FROM stdin;
\.


--
-- Data for Name: release_; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.release_ (releaseid, createdate, modifieddate, buildnumber, builddate) FROM stdin;
\.


--
-- Data for Name: report_asset; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.report_asset (inode, report_name, report_description, requires_input, ds, web_form_report) FROM stdin;
\.


--
-- Data for Name: report_parameter; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.report_parameter (inode, report_inode, parameter_description, parameter_name, class_type, default_value) FROM stdin;
\.


--
-- Data for Name: rule_action; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.rule_action (id, rule_id, priority, actionlet, mod_date) FROM stdin;
5eb64f68-c4c7-4b53-934c-67358fa7ae01	f371e13f-a2ed-4b74-afea-42e486eda82c	1	PersonaActionlet	\N
6e731d8a-1158-4fa2-8ff7-4bdaef78137e	534584eb-5164-455e-a118-222a7a8a9f50	1	PersonaActionlet	\N
ded05831-db16-406c-9b28-16eab1ecb402	2622534d-5805-47b3-9334-0b5bbb56731f	1	PersonaActionlet	\N
5f21da78-4d47-4882-a471-2f71627b348a	e3bf0b13-5886-4c27-a2da-37f739d2852b	1	PersonaActionlet	\N
4f8b7e21-808d-4f7a-9233-15cd8a10c297	21c77092-d638-41cd-b1dd-3bc5e4fffe60	1	PersonaActionlet	\N
56b3024f-0f91-4b06-8397-302f23c522fa	a29ba0ed-97a8-479c-abec-fc7ec729c326	1	PersonaActionlet	\N
50cd7463-db02-4db6-b018-27cc2b70bbaf	44da6828-bf51-42ab-9982-bd80e023d33a	1	PersonaActionlet	\N
\.


--
-- Data for Name: rule_action_pars; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.rule_action_pars (id, rule_action_id, paramkey, value) FROM stdin;
b7c50c8b-d581-4c43-8924-1151611b0efc	5eb64f68-c4c7-4b53-934c-67358fa7ae01	personaIdKey	792c7c9f-6b6f-427b-80ff-1643376c9999
7936a95a-6640-406e-b193-8777cde47120	6e731d8a-1158-4fa2-8ff7-4bdaef78137e	personaIdKey	792c7c9f-6b6f-427b-80ff-1643376c9999
0f5a030e-9018-4e4f-81f7-7f28e0e71413	ded05831-db16-406c-9b28-16eab1ecb402	personaIdKey	0ed8e71a-47c7-4b30-a6f2-3796aa71ba49
83173c2a-595b-4118-8360-15185211e291	5f21da78-4d47-4882-a471-2f71627b348a	personaIdKey	d948d85c-3bc8-4d85-b0aa-0e989b9ae235
a66ea929-a1df-4891-9ea0-5e7d2d0b580c	4f8b7e21-808d-4f7a-9233-15cd8a10c297	personaIdKey	792c7c9f-6b6f-427b-80ff-1643376c9999
5fedd87f-f494-493d-bcd2-1feee3437119	56b3024f-0f91-4b06-8397-302f23c522fa	personaIdKey	792c7c9f-6b6f-427b-80ff-1643376c9999
e0baa716-b721-4ce7-a532-d3b4b5793dce	50cd7463-db02-4db6-b018-27cc2b70bbaf	personaIdKey	0ed8e71a-47c7-4b30-a6f2-3796aa71ba49
\.


--
-- Data for Name: rule_condition; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.rule_condition (id, conditionlet, condition_group, comparison, operator, priority, mod_date) FROM stdin;
308d7c4d-3aaf-408f-9873-758eed75204b	UsersBrowserConditionlet	07bee53c-b920-45a0-ba1a-8d570c6417e4	fake-comparison	AND	1	2020-03-26 00:35:28.071
2de86d31-6e1f-4531-9586-d8c2ad518ca3	VisitedUrlConditionlet	5695f764-9e92-408b-8ed8-606004ec16d3	fake-comparison	AND	1	2020-03-26 00:35:28.098
0c32eace-bc5a-439f-98ac-7b12e3d82428	UsersBrowserConditionlet	e77edb97-3a9f-4411-b6e1-608878f0a863	fake-comparison	AND	1	2020-03-26 00:35:28.124
\.


--
-- Data for Name: rule_condition_group; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.rule_condition_group (id, rule_id, operator, priority, mod_date) FROM stdin;
07bee53c-b920-45a0-ba1a-8d570c6417e4	a29ba0ed-97a8-479c-abec-fc7ec729c326	AND	1	2020-03-26 00:35:28.065
5695f764-9e92-408b-8ed8-606004ec16d3	fc0f85a6-6853-4e51-ab5d-4122b3207202	AND	1	2020-03-26 00:35:28.091
e77edb97-3a9f-4411-b6e1-608878f0a863	44da6828-bf51-42ab-9982-bd80e023d33a	AND	1	2020-03-26 00:35:28.12
\.


--
-- Data for Name: rule_condition_value; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.rule_condition_value (id, condition_id, paramkey, value, priority) FROM stdin;
74d27ca8-337a-4061-bf18-a4e040f9b9fa	308d7c4d-3aaf-408f-9873-758eed75204b	browser	Chrome	0
f56b5f52-d1f5-458a-b139-ed33d433a4c4	308d7c4d-3aaf-408f-9873-758eed75204b	comparison	is	0
b8567e68-c1b6-464e-9167-fed4be12c70c	2de86d31-6e1f-4531-9586-d8c2ad518ca3	comparison	is	0
1cc412ab-d79d-413f-a7a4-3cef6256408e	2de86d31-6e1f-4531-9586-d8c2ad518ca3	has-visited-url	\N	0
dfe85bce-ecd6-47ef-bc9b-40daa5cb6f80	0c32eace-bc5a-439f-98ac-7b12e3d82428	browser	Firefox	0
84585546-05c2-4cb4-b947-dbb53cc3e27a	0c32eace-bc5a-439f-98ac-7b12e3d82428	comparison	is	0
\.


--
-- Data for Name: schemes_ir; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.schemes_ir (name, local_inode, remote_inode, endpoint_id) FROM stdin;
\.


--
-- Data for Name: sitelic; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.sitelic (id, serverid, license, lastping) FROM stdin;
\.


--
-- Data for Name: sitesearch_audit; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.sitesearch_audit (job_id, job_name, fire_date, incremental, start_date, end_date, host_list, all_hosts, lang_list, path, path_include, files_count, pages_count, urlmaps_count, index_name) FROM stdin;
\.


--
-- Data for Name: structure; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.structure (inode, name, description, default_structure, review_interval, reviewer_role, page_detail, structuretype, system, fixed, velocity_var_name, url_map_pattern, host, folder, expire_date_var, publish_date_var, mod_date) FROM stdin;
f4d7c1b8-2c88-4071-abf1-a5328977b07d	Language Variable	Default Content Type for Language Variables	f	\N	\N	\N	8	f	t	Languagevariable	\N	SYSTEM_HOST	SYSTEM_FOLDER	\N	\N	2020-03-26 00:35:04
8e850645-bb92-4fda-a765-e67063a59be0	Vanity URL	Default Content Type for Vanity URLs	f	\N	\N	\N	7	f	t	Vanityurl	\N	SYSTEM_HOST	SYSTEM_FOLDER	\N	\N	2020-03-26 00:35:04
4d21b6d8-1711-4ae6-9419-89e2b1ae5a06	Forms	Forms	f	\N	\N	\N	2	t	t	forms	\N	SYSTEM_HOST	SYSTEM_FOLDER	\N	\N	2020-03-26 00:35:04
c6e3a3c6-a0c6-494b-9ae8-bde7322bc68e	Device	Device previews for Edit Mode	f	\N	\N	\N	1	f	f	PreviewDevice	\N	SYSTEM_HOST	SYSTEM_FOLDER	\N	\N	2020-03-26 00:35:05
c938b15f-bcb6-49ef-8651-14d455a97045	Persona	Default Structure for Personas	f	\N	\N	\N	6	f	f	persona	\N	SYSTEM_HOST	SYSTEM_FOLDER	\N	\N	2020-03-26 00:35:06
c541abb1-69b3-4bc5-8430-5e09e5239cc8	Page	Default Structure for Pages	f	\N	\N	\N	5	f	t	htmlpageasset	\N	SYSTEM_HOST	SYSTEM_FOLDER	\N	\N	2020-03-26 01:06:09
2a3e91e4-fbbf-4876-8c5b-2233c1739b05	Rich Text	WYSIWYG rich text content	t	\N	\N	\N	1	f	f	webPageContent	\N	SYSTEM_HOST	SYSTEM_FOLDER	\N	\N	2020-03-26 00:35:08
f6259cc9-5d78-453e-8167-efd7b72b2e96	Event	Calendar and events	f	\N	\N	\N	1	f	f	calendarEvent	\N	SYSTEM_HOST	SYSTEM_FOLDER			2020-03-26 00:55:33
855a2d72-f2f3-4169-8b04-ac5157c4380c	Host	System hosts information	f	\N	\N	\N	1	t	t	Host	\N	SYSTEM_HOST	SYSTEM_FOLDER	\N	\N	2020-03-26 00:35:14
897cf4a9-171a-4204-accb-c1b498c813fe	Contact	General Contact Form	f	\N	\N	\N	3	f	f	Contact	\N	48190c8c-42c4-46af-8d1a-0cd5db894797	SYSTEM_FOLDER	\N	\N	2020-03-26 00:35:15
33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d	File	Default structure for all uploaded files	f	\N	\N	\N	4	f	t	FileAsset	\N	SYSTEM_HOST	SYSTEM_FOLDER	\N	\N	2020-03-26 00:35:15
\.


--
-- Data for Name: structures_ir; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.structures_ir (velocity_name, local_inode, remote_inode, endpoint_id) FROM stdin;
\.


--
-- Name: summary_404_seq; Type: SEQUENCE SET; Schema: public; Owner: dotcms_dev
--

SELECT pg_catalog.setval('public.summary_404_seq', 2, false);


--
-- Name: summary_content_seq; Type: SEQUENCE SET; Schema: public; Owner: dotcms_dev
--

SELECT pg_catalog.setval('public.summary_content_seq', 2, false);


--
-- Name: summary_pages_seq; Type: SEQUENCE SET; Schema: public; Owner: dotcms_dev
--

SELECT pg_catalog.setval('public.summary_pages_seq', 2, false);


--
-- Name: summary_period_seq; Type: SEQUENCE SET; Schema: public; Owner: dotcms_dev
--

SELECT pg_catalog.setval('public.summary_period_seq', 9, false);


--
-- Name: summary_referer_seq; Type: SEQUENCE SET; Schema: public; Owner: dotcms_dev
--

SELECT pg_catalog.setval('public.summary_referer_seq', 2, false);


--
-- Name: summary_seq; Type: SEQUENCE SET; Schema: public; Owner: dotcms_dev
--

SELECT pg_catalog.setval('public.summary_seq', 9, false);


--
-- Name: summary_visits_seq; Type: SEQUENCE SET; Schema: public; Owner: dotcms_dev
--

SELECT pg_catalog.setval('public.summary_visits_seq', 2, false);


--
-- Data for Name: system_event; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.system_event (identifier, event_type, payload, created, server_id) FROM stdin;
1cac471c-c999-4cb1-9da7-9aaf6f41c18a	SWITCH_SITE	{"type":"com.dotmarketing.beans.Host","visibility":"USER_SESSION","visibilityValue":{"user":"dotcms.org.1","sessionId":"DA0A3376D43B02A70F1DF4B381BC20A6"},"visibilityType":"com.dotcms.api.system.event.UserSessionBean","data":{"hostName":"demo.dotcms.com","googleMap":"AIzaSyDXvD7JA5Q8S5VgfviI8nDinAq9x5Utmu0","modDate":1580831056732,"aliases":"test.dotcms.com\\ntest2.dotcms.com\\nlocalhost\\n127.0.0.1","keywords":"CMS, Web Content Management, Open Source, Java, J2EE, DXP, NoCode, OSGI, Apache Velocity, Elasticsearch, RESTful Services, REST API, Workflows, Personalization, Multilingual, I18N, L10N, Internationalization, Localization, Docker CMS, Containerized CMS","description":"dotCMS starter site was designed to demonstrate what you can do with dotCMS.","type":"host","proxyEditModeUrl":"https://ematest.dotcms.com:8443","inode":"0c3418eb-4c27-4d71-937d-bf231399312a","hostname":"demo.dotcms.com","addThis":"ra-4e02119211875e7b","disabledWYSIWYG":[],"host":"SYSTEM_HOST","lastReview":1580831056724,"stInode":"855a2d72-f2f3-4169-8b04-ac5157c4380c","owner":"dotcms.org.1","nullProperties":["embeddedDashboard","wfExpireDate","wfPublishDate","wfNeverExpire","wfActionAssign","wfActionId","wfPublishTime","wfActionComments","wfExpireTime"],"identifier":"48190c8c-42c4-46af-8d1a-0cd5db894797","runDashboard":false,"languageId":1,"isDefault":true,"folder":"SYSTEM_FOLDER","googleAnalytics":"UA-9877660-3","tagStorage":"SYSTEM_HOST","isSystemHost":false,"sortOrder":0,"modUser":"dotcms.org.1","lowIndexPriority":false,"archived":false}}	1585197392132	e64a5620-9bd4-4e08-a53a-67a80079eea1
a388f334-8a03-4eca-a3c6-07ae6a4705ed	SESSION_DESTROYED	{"type":"java.lang.Long","visibility":"USER_SESSION","visibilityValue":{"user":"dotcms.org.1","sessionId":"DA0A3376D43B02A70F1DF4B381BC20A6"},"visibilityType":"com.dotcms.api.system.event.UserSessionBean","data":1585197392161}	1585197392161	e64a5620-9bd4-4e08-a53a-67a80079eea1
eef7e565-66b0-44ac-a102-99a87c12c836	SWITCH_SITE	{"type":"com.dotmarketing.beans.Host","visibility":"USER_SESSION","visibilityValue":{"user":"dotcms.org.1","sessionId":"DC46A631627F8DB3AFD3257BB41DFFFF"},"visibilityType":"com.dotcms.api.system.event.UserSessionBean","data":{"hostName":"demo.dotcms.com","googleMap":"AIzaSyDXvD7JA5Q8S5VgfviI8nDinAq9x5Utmu0","modDate":1580831056732,"aliases":"test.dotcms.com\\ntest2.dotcms.com\\nlocalhost\\n127.0.0.1","keywords":"CMS, Web Content Management, Open Source, Java, J2EE, DXP, NoCode, OSGI, Apache Velocity, Elasticsearch, RESTful Services, REST API, Workflows, Personalization, Multilingual, I18N, L10N, Internationalization, Localization, Docker CMS, Containerized CMS","description":"dotCMS starter site was designed to demonstrate what you can do with dotCMS.","type":"host","proxyEditModeUrl":"https://ematest.dotcms.com:8443","inode":"0c3418eb-4c27-4d71-937d-bf231399312a","hostname":"demo.dotcms.com","addThis":"ra-4e02119211875e7b","disabledWYSIWYG":[],"host":"SYSTEM_HOST","lastReview":1580831056724,"stInode":"855a2d72-f2f3-4169-8b04-ac5157c4380c","owner":"dotcms.org.1","nullProperties":["embeddedDashboard","wfExpireDate","wfPublishDate","wfNeverExpire","wfActionAssign","wfActionId","wfPublishTime","wfActionComments","wfExpireTime"],"identifier":"48190c8c-42c4-46af-8d1a-0cd5db894797","runDashboard":false,"languageId":1,"isDefault":true,"folder":"SYSTEM_FOLDER","googleAnalytics":"UA-9877660-3","tagStorage":"SYSTEM_HOST","isSystemHost":false,"sortOrder":0,"modUser":"dotcms.org.1","lowIndexPriority":false,"archived":false}}	1585197392167	e64a5620-9bd4-4e08-a53a-67a80079eea1
8c1dfbd8-8c70-4045-9599-d9e1e8874645	UPDATE_PORTLET_LAYOUTS	{"type":"com.dotcms.api.system.event.Void","visibility":"GLOBAL","data":{}}	1585197426661	e64a5620-9bd4-4e08-a53a-67a80079eea1
0a9704e2-3c46-49ba-b96f-9f178282b690	UPDATE_PORTLET_LAYOUTS	{"type":"com.dotcms.api.system.event.Void","visibility":"GLOBAL","data":{}}	1585197427929	e64a5620-9bd4-4e08-a53a-67a80079eea1
eb2aabce-14e4-4d6f-847c-365ee32026cc	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"water","sortOrder":2,"showOnMenu":true,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"Water","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1580830704131,"iDate":1571697040975,"type":"folder","inode":"f740c48e-c63b-4b83-bb20-036551c3aa26","identifier":"cb80d9d4-1b9c-46ee-a48a-a264fe4b8d30"}}	1585197978037	e64a5620-9bd4-4e08-a53a-67a80079eea1
cf225bbf-36a5-448c-9545-3d6a7070b12a	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"snow","sortOrder":0,"showOnMenu":true,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"Snow","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1580830704107,"iDate":1571696985436,"type":"folder","inode":"ed460584-5b81-4146-aced-4ee2dc2dfa53","identifier":"ba07fff1-bc22-45ab-82d6-cbd03b275dee"}}	1585197981459	e64a5620-9bd4-4e08-a53a-67a80079eea1
a79b91be-5009-4ae6-ad8c-2aee5e8a6e6d	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"outdoor","sortOrder":1,"showOnMenu":true,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"Outdoor","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1580830704127,"iDate":1571697151170,"type":"folder","owner":"86fe5be1-4624-4595-bf2d-af8d559414b1","inode":"c691731b-df6f-4c81-8ede-af2ffa795ac3","identifier":"a0814889-38c6-4633-b1d4-9565dc83358c"}}	1585197984747	e64a5620-9bd4-4e08-a53a-67a80079eea1
9d0dcd9c-4ea2-4770-98ac-bf99c605b75e	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"apparel","sortOrder":3,"showOnMenu":true,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"Apparel","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1580830704135,"iDate":1572033802654,"type":"folder","owner":"036fd43a-6d98-46e0-b22e-bae02cb86f0c","inode":"2dc8eb87-524d-455a-a905-6f6f613eb60f","identifier":"e4029054-fae9-46d9-a235-6a947b865470"}}	1585197987911	e64a5620-9bd4-4e08-a53a-67a80079eea1
2b667690-620b-40d6-a821-4c7c9739d534	UPDATE_PORTLET_LAYOUTS	{"type":"com.dotcms.api.system.event.Void","visibility":"GLOBAL","data":{}}	1585198387512	e64a5620-9bd4-4e08-a53a-67a80079eea1
29545207-6a5f-442e-9ec3-de39b46bee58	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"store","sortOrder":2,"showOnMenu":true,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"Shop","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1580830704146,"iDate":1563311506740,"type":"folder","inode":"8027c7b2-61cb-46f0-ac81-3771efdfbe4c","identifier":"cbdabf05-5506-4649-b531-49c18863d41a"}}	1585197991217	e64a5620-9bd4-4e08-a53a-67a80079eea1
af221846-134f-4675-9282-3b16453a2d3a	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"blogs","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"blogs","filesMasks":"*.jpg, *.gif, *.bmp, *.png, *.svg, *.webp, *.jpeg","defaultFileType":"d5ea385d-32ee-4f35-8172-d37f58d9cd7a","modDate":1568916673160,"iDate":1568916271024,"type":"folder","inode":"9716b18a-8b2f-44de-8c10-13f886c6f119","identifier":"2fa0a962-d913-41a2-969d-d115094807f0"}}	1585198002693	e64a5620-9bd4-4e08-a53a-67a80079eea1
201cf49f-a78c-417a-97ee-d1af71bac602	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"events","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"events","filesMasks":"*.jpg, *.gif, *.bmp, *.png, *.svg, *.webp, *.jpeg","defaultFileType":"d5ea385d-32ee-4f35-8172-d37f58d9cd7a","modDate":1568916698031,"iDate":1562786070981,"type":"folder","inode":"87314c30-cc80-4eb8-a7d6-dbabbb7afc45","identifier":"6d2a7c3a-1e4f-4de5-9ba1-d4ca973b8ec2"}}	1585198002703	e64a5620-9bd4-4e08-a53a-67a80079eea1
ac8163f2-58c6-43c4-904f-e1a94f607f86	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"beach","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"beach","filesMasks":"*.jpg, *.gif, *.bmp, *.png, *.svg, *.webp, *.jpeg","defaultFileType":"d5ea385d-32ee-4f35-8172-d37f58d9cd7a","modDate":1568916711397,"iDate":1567001241362,"type":"folder","inode":"c5eaf1a7-03c0-4f04-9e55-5f6c45d14e47","identifier":"b5713c0a-4822-487c-b91b-ca1977e4d24b"}}	1585198002714	e64a5620-9bd4-4e08-a53a-67a80079eea1
e79d3eb1-100c-461e-bfce-073fe4857ecc	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"surfing","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"surfing","filesMasks":"*.jpg, *.gif, *.bmp, *.png, *.svg, *.webp, *.jpeg","defaultFileType":"d5ea385d-32ee-4f35-8172-d37f58d9cd7a","modDate":1568916717664,"iDate":1567001271012,"type":"folder","inode":"9283ed27-c5fb-43d8-ba38-e7b2b628efcf","identifier":"740444be-cef8-4d87-a710-b07303cb3d4c"}}	1585198002723	e64a5620-9bd4-4e08-a53a-67a80079eea1
fe0f220f-7595-4ecb-bda1-19850e4e3683	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"winter","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"winter","filesMasks":"*.jpg, *.gif, *.bmp, *.png, *.svg, *.webp, *.jpeg","defaultFileType":"d5ea385d-32ee-4f35-8172-d37f58d9cd7a","modDate":1570030383491,"iDate":1567001201806,"type":"folder","inode":"3e924cd2-3bae-4e34-afbd-af5bb489992b","identifier":"18e0b4f0-7eb9-4d76-972d-0bee6a080c83"}}	1585198002730	e64a5620-9bd4-4e08-a53a-67a80079eea1
ac2b4e76-1eee-4121-80fb-fa3f119dcd0a	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"gallery","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"gallery","filesMasks":"*.jpg, *.gif, *.bmp, *.png, *.svg, *.webp, *.jpeg","defaultFileType":"d5ea385d-32ee-4f35-8172-d37f58d9cd7a","modDate":1568916704649,"iDate":1562870298935,"type":"folder","inode":"c0603b7a-b34a-466d-9dcc-590b35d07cbc","identifier":"8de2cb2b-2072-46ec-88c0-93206b2e4dec"}}	1585198002738	e64a5620-9bd4-4e08-a53a-67a80079eea1
edbcc83b-dc2f-4688-8295-b5a42993920d	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"pages","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"pages","filesMasks":"*.jpg, *.gif, *.bmp, *.png, *.svg, *.webp, *.jpeg","defaultFileType":"d5ea385d-32ee-4f35-8172-d37f58d9cd7a","modDate":1568916731208,"iDate":1564156741722,"type":"folder","inode":"d708807f-6dbc-4d84-add4-6caec90de177","identifier":"0668187e-aae0-4795-898d-a913b0eaec15"}}	1585198002745	e64a5620-9bd4-4e08-a53a-67a80079eea1
6a646465-1641-4471-84cc-64e2f4f4c12b	NOTIFICATION	{"type":"com.dotcms.notifications.bean.Notification","visibility":"ROLE","visibilityValue":"892ab105-f212-407f-8fb4-58ec59310a5e","visibilityType":"java.lang.String","data":{"groupId":"d06c7415-7b1a-4418-81ba-205f4a44ce23","notificationData":{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}},"level":"INFO","userId":"system","timeSent":1585198478523,"wasRead":false,"prettyDate":"seconds ago"}}	1585198478523	e64a5620-9bd4-4e08-a53a-67a80079eea1
a758efbf-80bf-4e40-af5a-4da7ed986e73	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"search","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"Site Search","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1558125850673,"iDate":1265746948000,"type":"folder","owner":"system","inode":"a1ea5a05-2460-4544-ae6a-f25f37a11db1","identifier":"303c6685-2405-4ebd-9043-b2cc26cce624"}}	1585197994573	e64a5620-9bd4-4e08-a53a-67a80079eea1
e0b0b45a-1278-411b-9099-d73c66057040	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"login","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"Login","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1558125850808,"iDate":1545076836332,"type":"folder","owner":"dotcms.org.1","inode":"6d81b94b-ce4e-4009-914c-e1d55e9071d4","identifier":"4310fde1-1c3b-4178-99e3-65a05891fa39"}}	1585197998144	e64a5620-9bd4-4e08-a53a-67a80079eea1
9944e124-2297-4e35-a36a-ebec78981c93	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"events","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"Events","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1564156243258,"iDate":1563288893328,"type":"folder","inode":"9522e0d3-8bd9-4cfa-851b-1109e950969e","identifier":"747ef955-f9a2-4800-a42d-90c1b3f17d31"}}	1585198006329	e64a5620-9bd4-4e08-a53a-67a80079eea1
0434ac66-91c4-4cb8-82ca-46e89ba25cf7	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"destinations","sortOrder":1,"showOnMenu":true,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"Destinations","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1580830704143,"iDate":1564156204761,"type":"folder","inode":"6c8a2ac4-36a7-4b01-b9c0-c2c1d91ddfdb","identifier":"60c40464-44fe-47fd-9fe6-820bebd28c76"}}	1585198010067	e64a5620-9bd4-4e08-a53a-67a80079eea1
65c7d0d1-e8a3-4591-a5d8-074c71db030b	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"containers","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"containers","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1558125851708,"iDate":1544628406386,"type":"folder","owner":"dotcms.org.1","inode":"b8a303ae-4cb4-40bf-9f27-b5b29b3350dc","identifier":"009f54c4-700c-43c1-8c2a-9d5a556c352a"}}	1585198081829	e64a5620-9bd4-4e08-a53a-67a80079eea1
94f49fbc-3a3b-44a9-965e-f98ca2edd797	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"sitemap","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"sitemap","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1571936111648,"iDate":1571935588821,"type":"folder","owner":"036fd43a-6d98-46e0-b22e-bae02cb86f0c","inode":"457e207e-911d-414d-83fa-13afe9e35882","identifier":"960cf1a7-3e47-409e-b9e5-e2d7dbe26135"}}	1585198086099	e64a5620-9bd4-4e08-a53a-67a80079eea1
c710877c-dcb0-4bad-a3a9-36eedb29aab5	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"apivtl","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"apivtl","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1571936100555,"iDate":1571936100551,"type":"folder","owner":"036fd43a-6d98-46e0-b22e-bae02cb86f0c","inode":"d4ab08ba-6ae6-4937-9fb4-b67d801ace72","identifier":"0b18cb65-24a7-414c-9cd4-42513d288a85"}}	1585198086112	e64a5620-9bd4-4e08-a53a-67a80079eea1
68607f77-1b67-4947-94c1-2606cb4bd539	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"images","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"images","filesMasks":"*.jpg, *.gif, *.bmp, *.png, *.jpeg, *.svp, *.webp, *.ico","defaultFileType":"d5ea385d-32ee-4f35-8172-d37f58d9cd7a","modDate":1571758192527,"iDate":1540474702297,"type":"folder","inode":"2ad0dd36-5b07-41ac-b9f5-c7c54085ac58","identifier":"8ddef32b-89f3-47ab-80bb-a46ec89046db"}}	1585198002752	e64a5620-9bd4-4e08-a53a-67a80079eea1
a103c94c-f456-4873-92ab-8355fc219e58	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"contact-us","sortOrder":3,"showOnMenu":true,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"Contact Us","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1580830704149,"iDate":1309281340788,"type":"folder","inode":"9c5e78a9-62ce-48e0-99ce-6817b0f5c2f3","identifier":"f2626d92-4c45-41aa-b749-769aff8f2d99"}}	1585198026457	e64a5620-9bd4-4e08-a53a-67a80079eea1
67976058-0d6e-4eba-81d9-310adb2d84c3	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"campaigns","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"campaigns","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1569443500160,"iDate":1569351760919,"type":"folder","inode":"0ba82678-af16-48ea-9b2a-14c001a1f6f5","identifier":"a20283e5-a24f-43f7-969a-a82b288eeccf"}}	1585198030221	e64a5620-9bd4-4e08-a53a-67a80079eea1
17099681-4388-47c9-bacb-b8da9bfe9b05	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"blog","sortOrder":0,"showOnMenu":true,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"Travel Blog","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1580830704139,"iDate":1314298912907,"type":"folder","inode":"fa455fb5-b961-4d0c-9e63-e79a8ba8622a","identifier":"3d765e9c-5267-4c5c-839c-4120cffe58f5"}}	1585198034089	e64a5620-9bd4-4e08-a53a-67a80079eea1
d1413945-9913-440b-8277-7b8d8b429b7f	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"wysiwyg","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"wysiwyg","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1568318932566,"iDate":1568318932556,"type":"folder","owner":"dotcms.org.1","inode":"d0c4f5b8-d8af-4245-9866-a03670cceb98","identifier":"57f33742-2423-48a8-b944-52a4bb6407f1"}}	1585198041280	e64a5620-9bd4-4e08-a53a-67a80079eea1
3a5f2481-5e93-46c8-9a93-5522070401b2	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"activities","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"activities","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1569271486490,"iDate":1569270451517,"type":"folder","inode":"753dc51c-459a-46d1-a0f5-0979f286257e","identifier":"44bfa13c-a6ce-47e0-b897-ca0b6a499c67"}}	1585198066003	e64a5620-9bd4-4e08-a53a-67a80079eea1
49d37cf3-e517-4155-a858-1fe26ab291ec	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"comments","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"comments","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1573226923653,"iDate":1573226923649,"type":"folder","owner":"036fd43a-6d98-46e0-b22e-bae02cb86f0c","inode":"e5259f74-3914-4bec-bd8c-030066d282c4","identifier":"e24a54c3-fa8e-4a50-82ef-06c6f6f8d65c"}}	1585198066013	e64a5620-9bd4-4e08-a53a-67a80079eea1
261d5d03-bd28-4df1-a11b-bc4c55ff9115	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"blog","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"blog","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1558125852127,"iDate":1539197606099,"type":"folder","owner":"","inode":"a0aad1d4-7d4a-4719-bfaf-6d623e16eff7","identifier":"de2e2bd0-2d21-43d8-993f-09f2c17ebd5a"}}	1585198066020	e64a5620-9bd4-4e08-a53a-67a80079eea1
6a69f250-1087-4532-a282-4c319367353e	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"breadcrumbs","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"breadcrumbs","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1564167013970,"iDate":1564167013968,"type":"folder","owner":"dotcms.org.1","inode":"ef1cbc74-26ad-4d41-9819-fe70fa851c79","identifier":"cf481949-e42c-4784-bdfa-abd1c158599c"}}	1585198066028	e64a5620-9bd4-4e08-a53a-67a80079eea1
181d27de-13e5-424c-bc94-1a8dc08e87c6	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"carousel","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"carousel","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1564168952724,"iDate":1539197606390,"type":"folder","inode":"ecd0b1a4-3cb8-41aa-bbfa-1a9e12eb562d","identifier":"f0521666-e009-4b21-b2f0-fd7752237ece"}}	1585198066036	e64a5620-9bd4-4e08-a53a-67a80079eea1
545f0e2b-70e0-45cd-8e16-970c63ca04e7	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"banner","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"banner","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1570123473805,"iDate":1570123473802,"type":"folder","owner":"036fd43a-6d98-46e0-b22e-bae02cb86f0c","inode":"64d9abae-0fc2-481a-a913-187ea76b889c","identifier":"86959e05-e0e4-410c-a5e4-67edf355e360"}}	1585198066045	e64a5620-9bd4-4e08-a53a-67a80079eea1
ffcddfae-a150-46a3-b24d-9908cdbf3cfb	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"page","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"page","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1570123507058,"iDate":1570123507055,"type":"folder","owner":"036fd43a-6d98-46e0-b22e-bae02cb86f0c","inode":"90f36380-33dd-4c7b-88ed-4929b0466254","identifier":"0e22d3a3-6b6b-42a7-828d-414ba263745c"}}	1585198066051	e64a5620-9bd4-4e08-a53a-67a80079eea1
c73e31f6-3e9f-4d33-85a1-50b4eed6c132	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"layouts","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"layouts","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1558125852402,"iDate":1555012406850,"type":"folder","owner":"","inode":"c9fa252e-399c-42a4-8bc6-3f2b4b4a2e5b","identifier":"957eedb5-dc68-4716-b015-558831aea55c"}}	1585198066058	e64a5620-9bd4-4e08-a53a-67a80079eea1
a21dc61d-a800-4cba-9aff-6c5e5191f228	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"custom-fields","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"custom-fields","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1558125851867,"iDate":1539197606490,"type":"folder","owner":"","inode":"d2b11d98-e43f-4ee9-908e-d22ec00bc019","identifier":"0d60f507-558c-4763-aea2-ce760d4fc1b0"}}	1585198066064	e64a5620-9bd4-4e08-a53a-67a80079eea1
6f410b56-ac99-4e11-b120-f633cd384e05	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"custom-workflow","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"custom-workflow","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1558125852019,"iDate":1539197606699,"type":"folder","owner":"","inode":"6f4d310c-d5df-4d11-8154-d0e0af8b43d5","identifier":"a86888c4-d819-4a17-8bd8-a215ef9fed16"}}	1585198066071	e64a5620-9bd4-4e08-a53a-67a80079eea1
4efe6359-9ed6-40ae-90d5-6d5a331944b7	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"destinations","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"destinations","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1566919721845,"iDate":1566855463549,"type":"folder","inode":"458cac06-767f-48d5-861f-4dd784823973","identifier":"b8c98874-6906-4671-a23f-3f83522a6d58"}}	1585198066077	e64a5620-9bd4-4e08-a53a-67a80079eea1
d5e2eef8-0322-4c30-835d-655636238ebe	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"events","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"events","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1564155660389,"iDate":1564155660387,"type":"folder","owner":"dotcms.org.1","inode":"ade5ca93-f748-4814-ac09-030fa0c92e47","identifier":"03cceef4-e22f-4b85-95fd-5381221830a0"}}	1585198066084	e64a5620-9bd4-4e08-a53a-67a80079eea1
e4fdaf1e-3b0e-4154-93ec-3c64988e7046	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"faq","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"faq","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1578682822327,"iDate":1578682822324,"type":"folder","owner":"86fe5be1-4624-4595-bf2d-af8d559414b1","inode":"abcc5617-24e4-40ba-a530-11ccb6addab6","identifier":"a96effef-dd17-4055-aa22-15d95c8084a3"}}	1585198066090	e64a5620-9bd4-4e08-a53a-67a80079eea1
c556c0f9-bf3c-4d95-bebf-20e55adf4731	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"forms","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"forms","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1558125851783,"iDate":1539197605824,"type":"folder","owner":"","inode":"10441a1b-f04e-4452-bdb5-05e86b86e667","identifier":"05d9ea58-07ef-404a-abb2-6347200bc4af"}}	1585198066097	e64a5620-9bd4-4e08-a53a-67a80079eea1
d6e3064b-1d27-4942-9113-3e317cfd7cf0	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"image-gallery","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"image-gallery","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1558125851997,"iDate":1539197606594,"type":"folder","owner":"","inode":"a2b60b3b-d107-4ebb-9b53-f4f2ada4011c","identifier":"8b1cc38b-71d6-4fa5-8cb4-b2edf46654d8"}}	1585198066103	e64a5620-9bd4-4e08-a53a-67a80079eea1
21c3a9ef-db47-4544-802d-8e2bccd7d6e0	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"login","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"login","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1558125851766,"iDate":1545077551374,"type":"folder","owner":"dotcms.org.1","inode":"d59fcbb3-ca8c-43c2-b780-418582a74e4e","identifier":"05bb31db-a19d-4a92-aa92-d5f61f14c0b8"}}	1585198066110	e64a5620-9bd4-4e08-a53a-67a80079eea1
9c454dc2-d8c2-43a1-8132-81e15291421c	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"site-search","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"site-search","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1558125851887,"iDate":1539197605647,"type":"folder","owner":"","inode":"f7ea8850-1b4e-476f-a082-b3c68a2abb9b","identifier":"6ee3a209-19de-4c90-8dba-039128595dae"}}	1585198066178	e64a5620-9bd4-4e08-a53a-67a80079eea1
32c8588c-9e2f-4a9b-982d-fe0a0b7b28ad	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"store","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"store","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1563311977367,"iDate":1539197605824,"type":"folder","inode":"275effdf-7237-4e24-ad1c-41fd7fac78f8","identifier":"762c4f16-06cd-43b0-9d87-ded8897f445d"}}	1585198066185	e64a5620-9bd4-4e08-a53a-67a80079eea1
2649115f-8c18-47b1-abfe-05f94f58abac	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"videos","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"videos","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1558125852039,"iDate":1539197606292,"type":"folder","owner":"","inode":"81ce824e-8462-4ec1-a5ef-7c8faadbf0f0","identifier":"b4aa3f5d-5603-4283-a0f4-e0bfa7a0b4d7"}}	1585198066192	e64a5620-9bd4-4e08-a53a-67a80079eea1
0fa2b175-3682-43c1-b108-8f0b9adbfc7d	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"visitor-profile","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"visitor profile","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1568993707909,"iDate":1568993668669,"type":"folder","inode":"389ad968-3c9e-4894-9ad3-726f961af35f","identifier":"2e3361ef-c3ad-4c7b-af98-107a3368605f"}}	1585198066199	e64a5620-9bd4-4e08-a53a-67a80079eea1
54403ef0-0e6e-4db2-9030-5911f9de8400	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"vtl","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"vtl","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1558125851681,"iDate":1539197605556,"type":"folder","owner":"","inode":"d274cc74-305f-4a61-9bdf-4695a01ab035","identifier":"8b2d19e8-80eb-4184-86b3-1376674b683a"}}	1585198066205	e64a5620-9bd4-4e08-a53a-67a80079eea1
2dfa1815-fe43-4d02-a617-cb6861cbb0a3	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"containers","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"containers","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1569958771033,"iDate":1569875062554,"type":"folder","inode":"4c51b543-cf43-4187-96a2-d2e209869c0c","identifier":"72bb97ab-9a56-4964-9010-1a34464432c7"}}	1585198072192	e64a5620-9bd4-4e08-a53a-67a80079eea1
e66dc097-2d48-4acf-aea1-947a1769bfa0	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"mixins","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"mixins","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1569447672160,"iDate":1569447672158,"type":"folder","owner":"","inode":"684169f6-b720-4f85-9b8b-e91da6edbcfd","identifier":"4cc7dc35-9599-4c9d-8a0b-90e6b697eca3"}}	1585198072201	e64a5620-9bd4-4e08-a53a-67a80079eea1
9df3fd45-b9e4-4a1c-8588-97edc0b89f41	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"custom","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"custom","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1569447671868,"iDate":1569447671866,"type":"folder","owner":"","inode":"cb532724-d3ac-49ad-bab8-34755239024b","identifier":"7174ab2a-b33e-45cb-874d-29d1ab8c9184"}}	1585198072207	e64a5620-9bd4-4e08-a53a-67a80079eea1
2cd9aa55-1b8c-4f25-b955-4fe114acd1a8	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"fonts","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"fonts","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1569943923714,"iDate":1569943923712,"type":"folder","owner":"","inode":"bf26f0cf-cb79-4664-bf41-21a4e31e42e5","identifier":"fc93f9d3-fc0e-4f85-a8ce-89bff886dc5c"}}	1585198072214	e64a5620-9bd4-4e08-a53a-67a80079eea1
80cda5d6-2d57-4424-bfc2-831c91acd4e6	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"plugins","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"plugins","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1569941257185,"iDate":1569941257182,"type":"folder","owner":"dotcms.org.1","inode":"7bfd2a8c-ec01-4819-998b-89bfffeb369d","identifier":"77d3dfd3-8074-4c6d-822e-97cb426d6fa3"}}	1585198072220	e64a5620-9bd4-4e08-a53a-67a80079eea1
557f6770-088c-4bc9-a9a1-1db6df963a03	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"css","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"css","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1569447875975,"iDate":1569444301803,"type":"folder","owner":"dotcms.org.1","inode":"c71719e0-7ee4-4bb1-a857-688c39eb92a6","identifier":"7a945d14-558b-4f76-bcb1-0bbf74adf0be"}}	1585198072226	e64a5620-9bd4-4e08-a53a-67a80079eea1
329b1eeb-20f5-4f24-bf07-696b50403991	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"fonts","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"fonts","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1569944132994,"iDate":1569944132992,"type":"folder","owner":"","inode":"1a77b1a4-b71e-459c-a112-2100b0e95fdb","identifier":"1dd73c1a-2534-4c31-919a-493d2b7c5feb"}}	1585198072232	e64a5620-9bd4-4e08-a53a-67a80079eea1
c1bfddda-dfb4-45d9-a839-f74be70a3c12	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"img","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"img","filesMasks":"*.jpg, *.gif, *.bmp, *.png, *.jpeg, *.svg, *.ico","defaultFileType":"d5ea385d-32ee-4f35-8172-d37f58d9cd7a","modDate":1569448322031,"iDate":1569444345170,"type":"folder","inode":"aef9487f-83ef-4f30-a200-167d608f4583","identifier":"3d7e73e7-dbaf-48e2-8443-592042c9fc1e"}}	1585198072238	e64a5620-9bd4-4e08-a53a-67a80079eea1
ceb38ade-41a3-47ed-b686-3fd22aa9c2b1	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"js","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"js","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1569447857084,"iDate":1569447857082,"type":"folder","owner":"","inode":"bd971317-50ec-48ed-87e1-a999b015f25c","identifier":"b21908e5-02eb-4e33-8060-6ed8a240794e"}}	1585198072244	e64a5620-9bd4-4e08-a53a-67a80079eea1
c527df93-d9b6-4027-8f58-e8d0f302fbff	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"landing-page","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"Landing Page","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1569438995291,"iDate":1569438983611,"type":"folder","inode":"ce00bd28-5f66-47f9-96ca-bbf0722a79aa","identifier":"57ec6b0f-b373-4910-84c4-bc04765fb883"}}	1585198072250	e64a5620-9bd4-4e08-a53a-67a80079eea1
009c9952-2e18-4875-9a24-44d841097297	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"containers","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"containers","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1569958816459,"iDate":1569958816457,"type":"folder","owner":"","inode":"dafeb75f-8544-4a7e-8195-cf6f6007e3d9","identifier":"9530c578-982e-41c1-bfc3-ebfc7711e598"}}	1585198072256	e64a5620-9bd4-4e08-a53a-67a80079eea1
4fb399b5-e933-45c9-beb4-f7fb94e7f86e	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"mixins","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"mixins","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1564177193709,"iDate":1564177193708,"type":"folder","owner":"","inode":"939422f0-44b8-4904-b449-bc37633213d9","identifier":"a3b03e97-b33a-44d3-8f59-d7328bb96c43"}}	1585198072266	e64a5620-9bd4-4e08-a53a-67a80079eea1
8cda7672-9abe-4200-a987-c226d55cbdf9	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"utilities","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"utilities","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1564177281236,"iDate":1564177281235,"type":"folder","owner":"","inode":"0c835cd6-8d18-4054-afa0-c26524779133","identifier":"71262c21-c05a-4a6e-b5f2-f23e834cd8e1"}}	1585198072276	e64a5620-9bd4-4e08-a53a-67a80079eea1
b62ed8b6-92e5-49dd-a2e0-5d24d8957cd5	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"bootstrap-4.0.0","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"bootstrap-4.0.0","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1564177161360,"iDate":1564177161359,"type":"folder","owner":"","inode":"58ff1b8d-2dd5-4530-888e-4a3f2efea1bc","identifier":"0878f49d-7caf-4a16-b3bd-108da376754f"}}	1585198072282	e64a5620-9bd4-4e08-a53a-67a80079eea1
c2deb961-bb08-406b-b100-7ed9e0743dd9	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"components","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"components","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1564177478886,"iDate":1564177478885,"type":"folder","owner":"","inode":"ab22d86e-ca6f-42f7-8338-a0f378de2acd","identifier":"2c7639ae-b89c-4842-9ac4-ef26f684abc2"}}	1585198072289	e64a5620-9bd4-4e08-a53a-67a80079eea1
2c4af565-fb06-4d52-962f-f2a72b0111e6	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"helpers","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"helpers","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1564177479152,"iDate":1564177479149,"type":"folder","owner":"","inode":"1c4a0e0a-99a2-47dd-8db9-82be948b590e","identifier":"1e57a2b9-0681-4c16-90cd-03af557bfe8b"}}	1585198072295	e64a5620-9bd4-4e08-a53a-67a80079eea1
5dbe1603-2793-4f3b-b29f-a7ec9b95b4e5	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"mixins","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"mixins","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1564177376844,"iDate":1564177376843,"type":"folder","owner":"","inode":"da4d541a-9c53-4634-b09d-4b7c60caac8c","identifier":"d324b734-5927-4c40-b778-66b7a83ecbcf"}}	1585198072302	e64a5620-9bd4-4e08-a53a-67a80079eea1
181b037f-fdeb-41e9-ac62-28bd63d48022	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"rd-navbar_themes","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"rd-navbar_themes","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1564177490015,"iDate":1564177490014,"type":"folder","owner":"","inode":"24b3e6bf-a8d5-4eb1-a32b-547892e37908","identifier":"ad764edf-3f3e-4308-a67e-3828877c5c93"}}	1585198072309	e64a5620-9bd4-4e08-a53a-67a80079eea1
e0e1da63-b4da-4158-b066-48901ac2a723	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"rd-navbar_includes","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"rd-navbar_includes","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1564177481824,"iDate":1564177481823,"type":"folder","owner":"","inode":"39c177f0-a2fb-4c58-95cc-f4a8f3e53b17","identifier":"2acaaf3b-e44b-4793-bcc3-199b88b48363"}}	1585198072316	e64a5620-9bd4-4e08-a53a-67a80079eea1
47415be9-56c6-4594-906b-f3fa264473a8	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"plugins","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"plugins","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1564177400065,"iDate":1564177400063,"type":"folder","owner":"","inode":"a2ba0bc1-4222-4201-a5c1-e61c6ac2edb3","identifier":"08a401a7-99e6-4f2a-ac64-ab1f75de1aca"}}	1585198072323	e64a5620-9bd4-4e08-a53a-67a80079eea1
26d8c77d-f00f-49a5-92c3-b758a8f5b89f	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"custom-styles","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"custom-styles","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1564177372058,"iDate":1564177372056,"type":"folder","owner":"","inode":"ad31fcfc-d922-4018-845b-12e43aee9435","identifier":"54f38c8b-2a60-4012-85c0-88833e7b63fb"}}	1585198072329	e64a5620-9bd4-4e08-a53a-67a80079eea1
d072842d-1204-4d2a-805d-5be4a0e11009	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"fonts","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"fonts","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1564177357563,"iDate":1564177357562,"type":"folder","owner":"","inode":"5c2ab759-35ec-418c-8730-f55ffa01c5e3","identifier":"fa9e58ac-2afd-4e9d-961c-696d2f0ec450"}}	1585198072336	e64a5620-9bd4-4e08-a53a-67a80079eea1
1d84887e-7daa-4c57-b169-bfa5cbaa3988	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"css","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"css","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1569865812225,"iDate":1564177150830,"type":"folder","inode":"0d7b90c3-5684-4127-a978-4db338f44f3a","identifier":"42355aa2-fc4f-4d43-af1f-795574ff9519"}}	1585198072343	e64a5620-9bd4-4e08-a53a-67a80079eea1
94651e8d-b2fb-4c41-8e1e-7aa55e38c7e4	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"fonts","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"fonts","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1562160807444,"iDate":1562160807443,"type":"folder","owner":"","inode":"8ae76e43-77c4-4feb-8195-3b24d3f707e0","identifier":"20ed1544-3d13-4550-a131-d99bc287ecce"}}	1585198072351	e64a5620-9bd4-4e08-a53a-67a80079eea1
8602dce2-be0a-4eba-81b0-ec58ce1fbce7	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"template-thumbnail","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"Template Thumbnail","filesMasks":"*.jpg, *.gif, *.bmp, *.png, *.svg, *.webp, *.jpeg","defaultFileType":"d5ea385d-32ee-4f35-8172-d37f58d9cd7a","modDate":1571758249236,"iDate":1567002769661,"type":"folder","inode":"63a5163d-dc46-44ef-9c6b-d881d0a3a45f","identifier":"0cc92847-8210-4ea8-9339-884327960861"}}	1585198072359	e64a5620-9bd4-4e08-a53a-67a80079eea1
0e07a74c-b276-4845-83ea-38972941bf8a	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"images","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"images","filesMasks":"*.jpg, *.gif, *.bmp, *.png, *.svg, *.webp, *.jpeg","defaultFileType":"d5ea385d-32ee-4f35-8172-d37f58d9cd7a","modDate":1571758256066,"iDate":1562170149636,"type":"folder","inode":"0dbd75ff-314f-4109-a4fe-43060574525d","identifier":"15459abc-f313-4d42-9530-78fd55fc8a00"}}	1585198072365	e64a5620-9bd4-4e08-a53a-67a80079eea1
0eec70e6-6a28-4e31-9650-3b64876e6033	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"js","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"js","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1558125852459,"iDate":1547665003595,"type":"folder","owner":"","inode":"aedccbb7-4d07-4f47-b6b6-713e0b29f016","identifier":"da7ecabd-66e9-43db-ae0c-8a5c0bcbaf2e"}}	1585198072372	e64a5620-9bd4-4e08-a53a-67a80079eea1
c63df17b-ffee-4676-8b6c-bc56e0e01b5c	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"travel","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"travel","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1564176627802,"iDate":1547665003325,"type":"folder","inode":"d7b0ebc2-37ca-4a5a-b769-e8a3ff187661","identifier":"13f88067-1e25-4e30-bc64-7e8f42ad542f"}}	1585198072377	e64a5620-9bd4-4e08-a53a-67a80079eea1
fd4b89f2-1d21-483c-8a6d-1fc819c5fe85	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"themes","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"themes","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1558125851695,"iDate":1350333314322,"type":"folder","owner":"","inode":"8c31a241-9dce-434a-8b77-ec902155307d","identifier":"4aa37d39-41c0-4a99-bb22-f7580dbe9dcc"}}	1585198072383	e64a5620-9bd4-4e08-a53a-67a80079eea1
831a271a-3c35-4d91-b067-bc4f7328f588	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"default","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"default","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1558125852308,"iDate":1547672625300,"type":"folder","owner":"system","inode":"f7da3dd4-104d-4086-91ea-67c715903bb1","identifier":"3ec54afb-1fea-4834-bcb1-0775932ec22c"}}	1585198077668	e64a5620-9bd4-4e08-a53a-67a80079eea1
923ef404-5a8c-4a51-b1ea-89245396e29a	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"application","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"Application","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1558125851055,"iDate":1330627788711,"type":"folder","owner":"dotcms.org.1","inode":"83bb5752-4264-43c4-84c8-28176603431a","identifier":"81f17c44-d2e2-49fb-a24e-a65ca8c6d9de"}}	1585198093169	e64a5620-9bd4-4e08-a53a-67a80079eea1
81a4b675-9032-4114-ab49-891668f99095	DELETE_FOLDER	{"type":"com.dotmarketing.portlets.folders.model.Folder","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"ROLES","visibilityValue":{"operator":"OR","rolesId":["654b0931-1027-41f7-ad4d-173115ed8ec1"]},"visibilityType":"com.dotcms.api.system.event.VisibilityRoles"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"name":"activities","sortOrder":0,"showOnMenu":false,"hostId":"48190c8c-42c4-46af-8d1a-0cd5db894797","title":"activities","filesMasks":"","defaultFileType":"33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d","modDate":1569271423411,"iDate":1568989236820,"type":"folder","inode":"513aec5b-3aaa-4df2-b306-83e77ba334d9","identifier":"44c81561-5f13-4da8-a3cd-1fd8d9ed968e"}}	1585198096543	e64a5620-9bd4-4e08-a53a-67a80079eea1
9ff26503-2e17-41e9-983a-ea55cba6c762	UN_PUBLISH_LINK	{"type":"com.dotmarketing.portlets.templates.model.Template","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"PERMISSION","visibilityValue":1,"visibilityType":"java.lang.Integer"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"body":"\\u003chtml\\u003e\\n \\u003chead\\u003e\\n  #dotParse(\\u0027//demo.dotcms.com/application/themes/travel/html_head.vtl\\u0027)\\n  \\u003clink rel\\u003d\\"stylesheet\\" type\\u003d\\"text/css\\" href\\u003d\\"/html/css/template/reset-fonts-grids.css\\" /\\u003e\\n \\u003c/head\\u003e\\n \\u003cbody\\u003e\\n  \\u003cdiv id\\u003d\\"resp-template\\" name\\u003d\\"globalContainer\\"\\u003e\\n   \\u003cdiv id\\u003d\\"hd-template\\"\\u003e\\n    #dotParse(\\u0027//demo.dotcms.com/application/themes/travel/header.vtl\\u0027)\\n   \\u003c/div\\u003e\\n   \\u003cdiv id\\u003d\\"bd-template\\"\\u003e\\n    \\u003cdiv id\\u003d\\"yui-main-template\\"\\u003e\\n     \\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody0\\"\\u003e\\n      #parseContainer(\\u0027854ad819-8381-434d-a70f-6e2330985ea4\\u0027,\\u00271572981893151\\u0027)\\n     \\u003c/div\\u003e\\n    \\u003c/div\\u003e\\n   \\u003c/div\\u003e\\n   \\u003cdiv id\\u003d\\"ft-template\\"\\u003e\\n    #dotParse(\\u0027//demo.dotcms.com/application/themes/travel/footer.vtl\\u0027)\\n   \\u003c/div\\u003e\\n  \\u003c/div\\u003e\\n \\u003c/body\\u003e\\n\\u003c/html\\u003e","image":"fe0f2be1-98eb-49c7-8193-8dd178446c96","drawed":true,"drawedBody":"\\u003cdiv id\\u003d\\"resp-template\\" name\\u003d\\"globalContainer\\"\\u003e\\u003cdiv id\\u003d\\"hd-template\\"\\u003e\\u003ch1\\u003eHeader\\u003c/h1\\u003e\\u003c/div\\u003e\\u003cdiv id\\u003d\\"bd-template\\"\\u003e\\u003cdiv id\\u003d\\"yui-main-template\\"\\u003e\\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody0\\"\\u003e\\u003cdiv class\\u003d\\"addContainerSpan\\"\\u003e\\u003ca href\\u003d\\"javascript: showAddContainerDialog(\\u0027splitBody0\\u0027);\\" title\\u003d\\"Add Container\\"\\u003e\\u003cspan class\\u003d\\"plusBlueIcon\\"\\u003e\\u003c/span\\u003eAdd Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cspan class\\u003d\\"titleContainerSpan\\" id\\u003d\\"splitBody0_span_854ad819-8381-434d-a70f-6e2330985ea4_1572981893151\\" title\\u003d\\"container_854ad819-8381-434d-a70f-6e2330985ea4\\"\\u003e\\u003cdiv class\\u003d\\"removeDiv\\"\\u003e\\u003ca href\\u003d\\"javascript: removeDrawedContainer(\\u0027splitBody0\\u0027,\\u0027854ad819-8381-434d-a70f-6e2330985ea4\\u0027,\\u00271572981893151\\u0027);\\" title\\u003d\\"Remove Container\\"\\u003e\\u003cspan class\\u003d\\"minusIcon\\"\\u003e\\u003c/span\\u003eRemove Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"clear\\"\\u003e\\u003c/div\\u003e\\u003ch2\\u003eContainer: Product Line\\u003c/h2\\u003e\\u003cp\\u003eLorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\\u003c/p\\u003e\\u003c/span\\u003e\\u003cdiv style\\u003d\\"display: none;\\" title\\u003d\\"container_854ad819-8381-434d-a70f-6e2330985ea4\\" id\\u003d\\"splitBody0_div_854ad819-8381-434d-a70f-6e2330985ea4_1572981893151\\"\\u003e#parseContainer(\\u0027854ad819-8381-434d-a70f-6e2330985ea4\\u0027,\\u00271572981893151\\u0027)\\r\\n\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003cdiv id\\u003d\\"ft-template\\"\\u003e\\u003ch1\\u003eFooter\\u003c/h1\\u003e\\u003c/div\\u003e\\u003c/div\\u003e","countAddContainer":0,"countContainers":0,"theme":"d7b0ebc2-37ca-4a5a-b769-e8a3ff187661","source":"DB","title":"Store - Product Line","friendlyName":"Template for listing the product lines in the store","modDate":1585198141004,"modUser":"dotcms.org.1","sortOrder":0,"showOnMenu":true,"iDate":1572981899288,"type":"template","inode":"0d0dc435-998d-439e-aad6-10cd7743f528","identifier":"52f0067c-83d9-48b6-8a74-56c6404788c7"}}	1585198141006	e64a5620-9bd4-4e08-a53a-67a80079eea1
cbe13e93-1a70-4126-858b-3396b1b05c46	ARCHIVE_LINK	{"type":"com.dotmarketing.portlets.templates.model.Template","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"PERMISSION","visibilityValue":1,"visibilityType":"java.lang.Integer"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"body":"\\u003chtml\\u003e\\n \\u003chead\\u003e\\n  #dotParse(\\u0027//demo.dotcms.com/application/themes/travel/html_head.vtl\\u0027)\\n  \\u003clink rel\\u003d\\"stylesheet\\" type\\u003d\\"text/css\\" href\\u003d\\"/html/css/template/reset-fonts-grids.css\\" /\\u003e\\n \\u003c/head\\u003e\\n \\u003cbody\\u003e\\n  \\u003cdiv id\\u003d\\"resp-template\\" name\\u003d\\"globalContainer\\"\\u003e\\n   \\u003cdiv id\\u003d\\"hd-template\\"\\u003e\\n    #dotParse(\\u0027//demo.dotcms.com/application/themes/travel/header.vtl\\u0027)\\n   \\u003c/div\\u003e\\n   \\u003cdiv id\\u003d\\"bd-template\\"\\u003e\\n    \\u003cdiv id\\u003d\\"yui-main-template\\"\\u003e\\n     \\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody0\\"\\u003e\\n      #parseContainer(\\u0027854ad819-8381-434d-a70f-6e2330985ea4\\u0027,\\u00271572981893151\\u0027)\\n     \\u003c/div\\u003e\\n    \\u003c/div\\u003e\\n   \\u003c/div\\u003e\\n   \\u003cdiv id\\u003d\\"ft-template\\"\\u003e\\n    #dotParse(\\u0027//demo.dotcms.com/application/themes/travel/footer.vtl\\u0027)\\n   \\u003c/div\\u003e\\n  \\u003c/div\\u003e\\n \\u003c/body\\u003e\\n\\u003c/html\\u003e","image":"fe0f2be1-98eb-49c7-8193-8dd178446c96","drawed":true,"drawedBody":"\\u003cdiv id\\u003d\\"resp-template\\" name\\u003d\\"globalContainer\\"\\u003e\\u003cdiv id\\u003d\\"hd-template\\"\\u003e\\u003ch1\\u003eHeader\\u003c/h1\\u003e\\u003c/div\\u003e\\u003cdiv id\\u003d\\"bd-template\\"\\u003e\\u003cdiv id\\u003d\\"yui-main-template\\"\\u003e\\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody0\\"\\u003e\\u003cdiv class\\u003d\\"addContainerSpan\\"\\u003e\\u003ca href\\u003d\\"javascript: showAddContainerDialog(\\u0027splitBody0\\u0027);\\" title\\u003d\\"Add Container\\"\\u003e\\u003cspan class\\u003d\\"plusBlueIcon\\"\\u003e\\u003c/span\\u003eAdd Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cspan class\\u003d\\"titleContainerSpan\\" id\\u003d\\"splitBody0_span_854ad819-8381-434d-a70f-6e2330985ea4_1572981893151\\" title\\u003d\\"container_854ad819-8381-434d-a70f-6e2330985ea4\\"\\u003e\\u003cdiv class\\u003d\\"removeDiv\\"\\u003e\\u003ca href\\u003d\\"javascript: removeDrawedContainer(\\u0027splitBody0\\u0027,\\u0027854ad819-8381-434d-a70f-6e2330985ea4\\u0027,\\u00271572981893151\\u0027);\\" title\\u003d\\"Remove Container\\"\\u003e\\u003cspan class\\u003d\\"minusIcon\\"\\u003e\\u003c/span\\u003eRemove Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"clear\\"\\u003e\\u003c/div\\u003e\\u003ch2\\u003eContainer: Product Line\\u003c/h2\\u003e\\u003cp\\u003eLorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\\u003c/p\\u003e\\u003c/span\\u003e\\u003cdiv style\\u003d\\"display: none;\\" title\\u003d\\"container_854ad819-8381-434d-a70f-6e2330985ea4\\" id\\u003d\\"splitBody0_div_854ad819-8381-434d-a70f-6e2330985ea4_1572981893151\\"\\u003e#parseContainer(\\u0027854ad819-8381-434d-a70f-6e2330985ea4\\u0027,\\u00271572981893151\\u0027)\\r\\n\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003cdiv id\\u003d\\"ft-template\\"\\u003e\\u003ch1\\u003eFooter\\u003c/h1\\u003e\\u003c/div\\u003e\\u003c/div\\u003e","countAddContainer":0,"countContainers":0,"theme":"d7b0ebc2-37ca-4a5a-b769-e8a3ff187661","source":"DB","title":"Store - Product Line","friendlyName":"Template for listing the product lines in the store","modDate":1585198146256,"modUser":"dotcms.org.1","sortOrder":0,"showOnMenu":true,"iDate":1572981899288,"type":"template","inode":"0d0dc435-998d-439e-aad6-10cd7743f528","identifier":"52f0067c-83d9-48b6-8a74-56c6404788c7"}}	1585198146296	e64a5620-9bd4-4e08-a53a-67a80079eea1
6acc3600-bf99-42a8-9992-63afedc72759	UN_PUBLISH_LINK	{"type":"com.dotmarketing.portlets.templates.model.Template","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"PERMISSION","visibilityValue":1,"visibilityType":"java.lang.Integer"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"body":"\\u003chtml\\u003e\\n \\u003chead\\u003e\\n  #dotParse(\\u0027//starter.dotcms.com/application/themes/landing-page/html_head.vtl\\u0027)\\n  \\u003clink rel\\u003d\\"stylesheet\\" type\\u003d\\"text/css\\" href\\u003d\\"/html/css/template/reset-fonts-grids.css\\" /\\u003e\\n \\u003c/head\\u003e\\n \\u003cbody\\u003e\\n  \\u003cdiv id\\u003d\\"resp-template\\" name\\u003d\\"globalContainer\\"\\u003e\\n   \\u003cdiv id\\u003d\\"hd-template\\"\\u003e\\n    #dotParse(\\u0027//starter.dotcms.com/application/themes/landing-page/header.vtl\\u0027)\\n   \\u003c/div\\u003e\\n   \\u003cdiv id\\u003d\\"bd-template\\"\\u003e\\n    \\u003cdiv id\\u003d\\"yui-main-template\\"\\u003e\\n     \\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody0\\"\\u003e\\n      \\u003cdiv class\\u003d\\"yui-g-template\\" id\\u003d\\"yui-g-template\\"\\u003e\\n       \\u003cdiv class\\u003d\\"yui-u-template first\\" id\\u003d\\"0_yui-u-grid-1\\"\\u003e\\n        #parseContainer(\\u002769b3d24d-7e80-4be6-b04a-d352d16493ee\\u0027,\\u00271570474272766\\u0027)\\n       \\u003c/div\\u003e\\n       \\u003cdiv class\\u003d\\"yui-u-template\\" id\\u003d\\"0_yui-u-grid-2\\"\\u003e\\n        #parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271570474279795\\u0027)\\n       \\u003c/div\\u003e\\n      \\u003c/div\\u003e\\n     \\u003c/div\\u003e\\n     \\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody1\\"\\u003e\\n      \\u003cdiv class\\u003d\\"yui-g-template\\" id\\u003d\\"yui-g-template\\"\\u003e\\n       \\u003cdiv class\\u003d\\"yui-u-template first\\" id\\u003d\\"1_yui-u-grid-1\\"\\u003e\\n        #parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271569962310124\\u0027)\\n       \\u003c/div\\u003e\\n       \\u003cdiv class\\u003d\\"yui-u-template\\" id\\u003d\\"1_yui-u-grid-2\\"\\u003e\\n        #parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271569962338553\\u0027)\\n       \\u003c/div\\u003e\\n      \\u003c/div\\u003e\\n     \\u003c/div\\u003e\\n     \\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody2\\"\\u003e\\n      \\u003cdiv class\\u003d\\"yui-g-template\\" id\\u003d\\"yui-js-template\\"\\u003e\\n       \\u003cdiv class\\u003d\\"yui-g-template\\" id\\u003d\\"yui-g-template\\"\\u003e\\n        \\u003cdiv class\\u003d\\"yui-u-template first\\" id\\u003d\\"2_yui-u-grid-1\\"\\u003e\\n         #parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271569962351862\\u0027)\\n        \\u003c/div\\u003e\\n        \\u003cdiv class\\u003d\\"yui-u-template\\" id\\u003d\\"2_yui-u-grid-2\\"\\u003e\\n         #parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271569962355912\\u0027)\\n        \\u003c/div\\u003e\\n       \\u003c/div\\u003e\\n       \\u003cdiv class\\u003d\\"yui-g-template\\" id\\u003d\\"yui-g-template\\" style\\u003d\\"margin-left:10px\\"\\u003e\\n        \\u003cdiv class\\u003d\\"yui-u-template first\\" id\\u003d\\"2_yui-u-grid-3\\"\\u003e\\n         #parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271569962359713\\u0027)\\n        \\u003c/div\\u003e\\n        \\u003cdiv class\\u003d\\"yui-u-template\\" id\\u003d\\"2_yui-u-grid-4\\"\\u003e\\n         #parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271569962363832\\u0027)\\n        \\u003c/div\\u003e\\n       \\u003c/div\\u003e\\n      \\u003c/div\\u003e\\n     \\u003c/div\\u003e\\n     \\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody3\\"\\u003e\\n      #parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271569962376026\\u0027)\\n     \\u003c/div\\u003e\\n    \\u003c/div\\u003e\\n   \\u003c/div\\u003e\\n   \\u003cdiv id\\u003d\\"ft-template\\"\\u003e\\n    #dotParse(\\u0027//starter.dotcms.com/application/themes/landing-page/footer.vtl\\u0027)\\n   \\u003c/div\\u003e\\n  \\u003c/div\\u003e\\n \\u003c/body\\u003e\\n\\u003c/html\\u003e","image":"cf7968a1-59be-4ca3-a744-5401d6c68c53","drawed":true,"drawedBody":"\\u003cdiv id\\u003d\\"resp-template\\" name\\u003d\\"globalContainer\\"\\u003e\\u003cdiv id\\u003d\\"hd-template\\"\\u003e\\u003ch1\\u003eHeader\\u003c/h1\\u003e\\u003c/div\\u003e\\u003cdiv id\\u003d\\"bd-template\\"\\u003e\\u003cdiv id\\u003d\\"yui-main-template\\"\\u003e\\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody0\\"\\u003e\\u003cdiv class\\u003d\\"yui-g-template\\" id\\u003d\\"yui-g-template\\"\\u003e\\u003cdiv class\\u003d\\"yui-u-template first\\" id\\u003d\\"0_yui-u-grid-1\\"\\u003e\\u003cdiv class\\u003d\\"addContainerSpan\\"\\u003e\\u003ca href\\u003d\\"javascript: showAddContainerDialog(\\u00270_yui-u-grid-1\\u0027);\\" title\\u003d\\"Add Container\\"\\u003e\\u003cspan class\\u003d\\"plusBlueIcon\\"\\u003e\\u003c/span\\u003eAdd Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cspan class\\u003d\\"titleContainerSpan\\" id\\u003d\\"0_yui-u-grid-1_span_69b3d24d-7e80-4be6-b04a-d352d16493ee_1570474272766\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\"\\u003e\\u003cdiv class\\u003d\\"removeDiv\\"\\u003e\\u003ca href\\u003d\\"javascript: removeDrawedContainer(\\u00270_yui-u-grid-1\\u0027,\\u002769b3d24d-7e80-4be6-b04a-d352d16493ee\\u0027,\\u00271570474272766\\u0027);\\" title\\u003d\\"Remove Container\\"\\u003e\\u003cspan class\\u003d\\"minusIcon\\"\\u003e\\u003c/span\\u003eRemove Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"clear\\"\\u003e\\u003c/div\\u003e\\u003ch2\\u003eContainer: Default\\u003c/h2\\u003e\\u003cp\\u003eLorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\\u003c/p\\u003e\\u003c/span\\u003e\\u003cdiv style\\u003d\\"display: none;\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\" id\\u003d\\"0_yui-u-grid-1_div_69b3d24d-7e80-4be6-b04a-d352d16493ee_1570474272766\\"\\u003e#parseContainer(\\u002769b3d24d-7e80-4be6-b04a-d352d16493ee\\u0027,\\u00271570474272766\\u0027)\\r\\n\\u003c/div\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"yui-u-template\\" id\\u003d\\"0_yui-u-grid-2\\"\\u003e\\u003cdiv class\\u003d\\"addContainerSpan\\"\\u003e\\u003ca href\\u003d\\"javascript: showAddContainerDialog(\\u00270_yui-u-grid-2\\u0027);\\" title\\u003d\\"Add Container\\"\\u003e\\u003cspan class\\u003d\\"plusBlueIcon\\"\\u003e\\u003c/span\\u003eAdd Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cspan class\\u003d\\"titleContainerSpan\\" id\\u003d\\"0_yui-u-grid-2_span_69b3d24d-7e80-4be6-b04a-d352d16493ee_1570474279795\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\"\\u003e\\u003cdiv class\\u003d\\"removeDiv\\"\\u003e\\u003ca href\\u003d\\"javascript: removeDrawedContainer(\\u00270_yui-u-grid-2\\u0027,\\u002769b3d24d-7e80-4be6-b04a-d352d16493ee\\u0027,\\u00271570474279795\\u0027);\\" title\\u003d\\"Remove Container\\"\\u003e\\u003cspan class\\u003d\\"minusIcon\\"\\u003e\\u003c/span\\u003eRemove Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"clear\\"\\u003e\\u003c/div\\u003e\\u003ch2\\u003eContainer: Default\\u003c/h2\\u003e\\u003cp\\u003eLorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\\u003c/p\\u003e\\u003c/span\\u003e\\u003cdiv style\\u003d\\"display: none;\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\" id\\u003d\\"0_yui-u-grid-2_div_69b3d24d-7e80-4be6-b04a-d352d16493ee_1570474279795\\"\\u003e#parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271570474279795\\u0027)\\r\\n\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody1\\"\\u003e\\u003cdiv class\\u003d\\"yui-g-template\\" id\\u003d\\"yui-g-template\\"\\u003e\\u003cdiv class\\u003d\\"yui-u-template first\\" id\\u003d\\"1_yui-u-grid-1\\"\\u003e\\u003cdiv class\\u003d\\"addContainerSpan\\"\\u003e\\u003ca href\\u003d\\"javascript: showAddContainerDialog(\\u00271_yui-u-grid-1\\u0027);\\" title\\u003d\\"Add Container\\"\\u003e\\u003cspan class\\u003d\\"plusBlueIcon\\"\\u003e\\u003c/span\\u003eAdd Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cspan class\\u003d\\"titleContainerSpan\\" id\\u003d\\"1_yui-u-grid-1_span_69b3d24d-7e80-4be6-b04a-d352d16493ee_1569962310124\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\"\\u003e\\u003cdiv class\\u003d\\"removeDiv\\"\\u003e\\u003ca href\\u003d\\"javascript: removeDrawedContainer(\\u00271_yui-u-grid-1\\u0027,\\u002769b3d24d-7e80-4be6-b04a-d352d16493ee\\u0027,\\u00271569962310124\\u0027);\\" title\\u003d\\"Remove Container\\"\\u003e\\u003cspan class\\u003d\\"minusIcon\\"\\u003e\\u003c/span\\u003eRemove Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"clear\\"\\u003e\\u003c/div\\u003e\\u003ch2\\u003eContainer: Default\\u003c/h2\\u003e\\u003cp\\u003eLorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\\u003c/p\\u003e\\u003c/span\\u003e\\u003cdiv style\\u003d\\"display: none;\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\" id\\u003d\\"1_yui-u-grid-1_div_69b3d24d-7e80-4be6-b04a-d352d16493ee_1569962310124\\"\\u003e#parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271569962310124\\u0027)\\r\\n\\u003c/div\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"yui-u-template\\" id\\u003d\\"1_yui-u-grid-2\\"\\u003e\\u003cdiv class\\u003d\\"addContainerSpan\\"\\u003e\\u003ca href\\u003d\\"javascript: showAddContainerDialog(\\u00271_yui-u-grid-2\\u0027);\\" title\\u003d\\"Add Container\\"\\u003e\\u003cspan class\\u003d\\"plusBlueIcon\\"\\u003e\\u003c/span\\u003eAdd Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cspan class\\u003d\\"titleContainerSpan\\" id\\u003d\\"1_yui-u-grid-2_span_69b3d24d-7e80-4be6-b04a-d352d16493ee_1569962338553\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\"\\u003e\\u003cdiv class\\u003d\\"removeDiv\\"\\u003e\\u003ca href\\u003d\\"javascript: removeDrawedContainer(\\u00271_yui-u-grid-2\\u0027,\\u002769b3d24d-7e80-4be6-b04a-d352d16493ee\\u0027,\\u00271569962338553\\u0027);\\" title\\u003d\\"Remove Container\\"\\u003e\\u003cspan class\\u003d\\"minusIcon\\"\\u003e\\u003c/span\\u003eRemove Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"clear\\"\\u003e\\u003c/div\\u003e\\u003ch2\\u003eContainer: Default\\u003c/h2\\u003e\\u003cp\\u003eLorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\\u003c/p\\u003e\\u003c/span\\u003e\\u003cdiv style\\u003d\\"display: none;\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\" id\\u003d\\"1_yui-u-grid-2_div_69b3d24d-7e80-4be6-b04a-d352d16493ee_1569962338553\\"\\u003e#parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271569962338553\\u0027)\\r\\n\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody2\\"\\u003e\\u003cdiv class\\u003d\\"yui-g-template\\" id\\u003d\\"yui-js-template\\"\\u003e\\u003cdiv class\\u003d\\"yui-g-template\\" id\\u003d\\"yui-g-template\\"\\u003e\\u003cdiv class\\u003d\\"yui-u-template first\\" id\\u003d\\"2_yui-u-grid-1\\"\\u003e\\u003cdiv class\\u003d\\"addContainerSpan\\"\\u003e\\u003ca href\\u003d\\"javascript: showAddContainerDialog(\\u00272_yui-u-grid-1\\u0027);\\" title\\u003d\\"Add Container\\"\\u003e\\u003cspan class\\u003d\\"plusBlueIcon\\"\\u003e\\u003c/span\\u003eAdd Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cspan class\\u003d\\"titleContainerSpan\\" id\\u003d\\"2_yui-u-grid-1_span_69b3d24d-7e80-4be6-b04a-d352d16493ee_1569962351862\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\"\\u003e\\u003cdiv class\\u003d\\"removeDiv\\"\\u003e\\u003ca href\\u003d\\"javascript: removeDrawedContainer(\\u00272_yui-u-grid-1\\u0027,\\u002769b3d24d-7e80-4be6-b04a-d352d16493ee\\u0027,\\u00271569962351862\\u0027);\\" title\\u003d\\"Remove Container\\"\\u003e\\u003cspan class\\u003d\\"minusIcon\\"\\u003e\\u003c/span\\u003eRemove Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"clear\\"\\u003e\\u003c/div\\u003e\\u003ch2\\u003eContainer: Default\\u003c/h2\\u003e\\u003cp\\u003eLorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\\u003c/p\\u003e\\u003c/span\\u003e\\u003cdiv style\\u003d\\"display: none;\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\" id\\u003d\\"2_yui-u-grid-1_div_69b3d24d-7e80-4be6-b04a-d352d16493ee_1569962351862\\"\\u003e#parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271569962351862\\u0027)\\r\\n\\u003c/div\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"yui-u-template\\" id\\u003d\\"2_yui-u-grid-2\\"\\u003e\\u003cdiv class\\u003d\\"addContainerSpan\\"\\u003e\\u003ca href\\u003d\\"javascript: showAddContainerDialog(\\u00272_yui-u-grid-2\\u0027);\\" title\\u003d\\"Add Container\\"\\u003e\\u003cspan class\\u003d\\"plusBlueIcon\\"\\u003e\\u003c/span\\u003eAdd Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cspan class\\u003d\\"titleContainerSpan\\" id\\u003d\\"2_yui-u-grid-2_span_69b3d24d-7e80-4be6-b04a-d352d16493ee_1569962355912\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\"\\u003e\\u003cdiv class\\u003d\\"removeDiv\\"\\u003e\\u003ca href\\u003d\\"javascript: removeDrawedContainer(\\u00272_yui-u-grid-2\\u0027,\\u002769b3d24d-7e80-4be6-b04a-d352d16493ee\\u0027,\\u00271569962355912\\u0027);\\" title\\u003d\\"Remove Container\\"\\u003e\\u003cspan class\\u003d\\"minusIcon\\"\\u003e\\u003c/span\\u003eRemove Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"clear\\"\\u003e\\u003c/div\\u003e\\u003ch2\\u003eContainer: Default\\u003c/h2\\u003e\\u003cp\\u003eLorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\\u003c/p\\u003e\\u003c/span\\u003e\\u003cdiv style\\u003d\\"display: none;\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\" id\\u003d\\"2_yui-u-grid-2_div_69b3d24d-7e80-4be6-b04a-d352d16493ee_1569962355912\\"\\u003e#parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271569962355912\\u0027)\\r\\n\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"yui-g-template\\" id\\u003d\\"yui-g-template\\" style\\u003d\\"margin-left:10px\\"\\u003e\\u003cdiv class\\u003d\\"yui-u-template first\\" id\\u003d\\"2_yui-u-grid-3\\"\\u003e\\u003cdiv class\\u003d\\"addContainerSpan\\"\\u003e\\u003ca href\\u003d\\"javascript: showAddContainerDialog(\\u00272_yui-u-grid-3\\u0027);\\" title\\u003d\\"Add Container\\"\\u003e\\u003cspan class\\u003d\\"plusBlueIcon\\"\\u003e\\u003c/span\\u003eAdd Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cspan class\\u003d\\"titleContainerSpan\\" id\\u003d\\"2_yui-u-grid-3_span_69b3d24d-7e80-4be6-b04a-d352d16493ee_1569962359713\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\"\\u003e\\u003cdiv class\\u003d\\"removeDiv\\"\\u003e\\u003ca href\\u003d\\"javascript: removeDrawedContainer(\\u00272_yui-u-grid-3\\u0027,\\u002769b3d24d-7e80-4be6-b04a-d352d16493ee\\u0027,\\u00271569962359713\\u0027);\\" title\\u003d\\"Remove Container\\"\\u003e\\u003cspan class\\u003d\\"minusIcon\\"\\u003e\\u003c/span\\u003eRemove Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"clear\\"\\u003e\\u003c/div\\u003e\\u003ch2\\u003eContainer: Default\\u003c/h2\\u003e\\u003cp\\u003eLorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\\u003c/p\\u003e\\u003c/span\\u003e\\u003cdiv style\\u003d\\"display: none;\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\" id\\u003d\\"2_yui-u-grid-3_div_69b3d24d-7e80-4be6-b04a-d352d16493ee_1569962359713\\"\\u003e#parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271569962359713\\u0027)\\r\\n\\u003c/div\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"yui-u-template\\" id\\u003d\\"2_yui-u-grid-4\\"\\u003e\\u003cdiv class\\u003d\\"addContainerSpan\\"\\u003e\\u003ca href\\u003d\\"javascript: showAddContainerDialog(\\u00272_yui-u-grid-4\\u0027);\\" title\\u003d\\"Add Container\\"\\u003e\\u003cspan class\\u003d\\"plusBlueIcon\\"\\u003e\\u003c/span\\u003eAdd Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cspan class\\u003d\\"titleContainerSpan\\" id\\u003d\\"2_yui-u-grid-4_span_69b3d24d-7e80-4be6-b04a-d352d16493ee_1569962363832\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\"\\u003e\\u003cdiv class\\u003d\\"removeDiv\\"\\u003e\\u003ca href\\u003d\\"javascript: removeDrawedContainer(\\u00272_yui-u-grid-4\\u0027,\\u002769b3d24d-7e80-4be6-b04a-d352d16493ee\\u0027,\\u00271569962363832\\u0027);\\" title\\u003d\\"Remove Container\\"\\u003e\\u003cspan class\\u003d\\"minusIcon\\"\\u003e\\u003c/span\\u003eRemove Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"clear\\"\\u003e\\u003c/div\\u003e\\u003ch2\\u003eContainer: Default\\u003c/h2\\u003e\\u003cp\\u003eLorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\\u003c/p\\u003e\\u003c/span\\u003e\\u003cdiv style\\u003d\\"display: none;\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\" id\\u003d\\"2_yui-u-grid-4_div_69b3d24d-7e80-4be6-b04a-d352d16493ee_1569962363832\\"\\u003e#parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271569962363832\\u0027)\\r\\n\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody3\\"\\u003e\\u003cdiv class\\u003d\\"addContainerSpan\\"\\u003e\\u003ca href\\u003d\\"javascript: showAddContainerDialog(\\u0027splitBody3\\u0027);\\" title\\u003d\\"Add Container\\"\\u003e\\u003cspan class\\u003d\\"plusBlueIcon\\"\\u003e\\u003c/span\\u003eAdd Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cspan class\\u003d\\"titleContainerSpan\\" id\\u003d\\"splitBody3_span_69b3d24d-7e80-4be6-b04a-d352d16493ee_1569962376026\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\"\\u003e\\u003cdiv class\\u003d\\"removeDiv\\"\\u003e\\u003ca href\\u003d\\"javascript: removeDrawedContainer(\\u0027splitBody3\\u0027,\\u002769b3d24d-7e80-4be6-b04a-d352d16493ee\\u0027,\\u00271569962376026\\u0027);\\" title\\u003d\\"Remove Container\\"\\u003e\\u003cspan class\\u003d\\"minusIcon\\"\\u003e\\u003c/span\\u003eRemove Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"clear\\"\\u003e\\u003c/div\\u003e\\u003ch2\\u003eContainer: Default\\u003c/h2\\u003e\\u003cp\\u003eLorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\\u003c/p\\u003e\\u003c/span\\u003e\\u003cdiv style\\u003d\\"display: none;\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\" id\\u003d\\"splitBody3_div_69b3d24d-7e80-4be6-b04a-d352d16493ee_1569962376026\\"\\u003e#parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271569962376026\\u0027)\\r\\n\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003cdiv id\\u003d\\"ft-template\\"\\u003e\\u003ch1\\u003eFooter\\u003c/h1\\u003e\\u003c/div\\u003e\\u003c/div\\u003e","countAddContainer":0,"countContainers":0,"theme":"ce00bd28-5f66-47f9-96ca-bbf0722a79aa","source":"DB","title":"Landing Page","friendlyName":"Marketing Landing Page","modDate":1585198148815,"modUser":"dotcms.org.1","sortOrder":0,"showOnMenu":true,"iDate":1571781566313,"type":"template","inode":"3a79250a-cd9c-455f-b41c-64a18088cd93","identifier":"fde4c167-edf4-4699-8a3a-0bf155067555"}}	1585198148816	e64a5620-9bd4-4e08-a53a-67a80079eea1
82fa010d-a282-4b58-b469-6124da2762c8	UN_PUBLISH_LINK	{"type":"com.dotmarketing.portlets.templates.model.Template","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"PERMISSION","visibilityValue":1,"visibilityType":"java.lang.Integer"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"body":"\\u003chtml\\u003e\\n \\u003chead\\u003e\\n  #dotParse(\\u0027//starter.dotcms.com/application/themes/travel/html_head.vtl\\u0027)\\n  \\u003clink rel\\u003d\\"stylesheet\\" type\\u003d\\"text/css\\" href\\u003d\\"/html/css/template/reset-fonts-grids.css\\" /\\u003e\\n \\u003c/head\\u003e\\n \\u003cbody\\u003e\\n  \\u003cdiv id\\u003d\\"resp-template\\" name\\u003d\\"globalContainer\\"\\u003e\\n   \\u003cdiv id\\u003d\\"hd-template\\"\\u003e\\n    #dotParse(\\u0027//starter.dotcms.com/application/themes/travel/header.vtl\\u0027)\\n   \\u003c/div\\u003e\\n   \\u003cdiv id\\u003d\\"bd-template\\"\\u003e\\n    \\u003cdiv id\\u003d\\"yui-main-template\\"\\u003e\\n     \\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody0\\"\\u003e\\n      #parseContainer(\\u00275a07f889-4536-4956-aa6e-e7967969ec3f\\u0027,\\u00271567007125001\\u0027)\\n     \\u003c/div\\u003e\\n     \\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody1\\"\\u003e\\n      \\u003cdiv class\\u003d\\"yui-g-template\\" id\\u003d\\"yui-g-template\\"\\u003e\\n       \\u003cdiv class\\u003d\\"yui-u-template first\\" id\\u003d\\"1_yui-u-grid-1\\"\\u003e\\n        #parseContainer(\\u002769b3d24d-7e80-4be6-b04a-d352d16493ee\\u0027,\\u00271567007147855\\u0027)\\n       \\u003c/div\\u003e\\n       \\u003cdiv class\\u003d\\"yui-u-template\\" id\\u003d\\"1_yui-u-grid-2\\"\\u003e\\n        #parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271567007153936\\u0027)\\n       \\u003c/div\\u003e\\n      \\u003c/div\\u003e\\n     \\u003c/div\\u003e\\n     \\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody3\\"\\u003e\\n      #parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271567007193334\\u0027)\\n     \\u003c/div\\u003e\\n    \\u003c/div\\u003e\\n   \\u003c/div\\u003e\\n   \\u003cdiv id\\u003d\\"ft-template\\"\\u003e\\n    #dotParse(\\u0027//starter.dotcms.com/application/themes/travel/footer.vtl\\u0027)\\n   \\u003c/div\\u003e\\n  \\u003c/div\\u003e\\n \\u003c/body\\u003e\\n\\u003c/html\\u003e","image":"","drawed":true,"drawedBody":"\\u003cdiv id\\u003d\\"resp-template\\" name\\u003d\\"globalContainer\\"\\u003e\\u003cdiv id\\u003d\\"hd-template\\"\\u003e\\u003ch1\\u003eHeader\\u003c/h1\\u003e\\u003c/div\\u003e\\u003cdiv id\\u003d\\"bd-template\\"\\u003e\\u003cdiv id\\u003d\\"yui-main-template\\"\\u003e\\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody0\\"\\u003e\\u003cdiv class\\u003d\\"addContainerSpan\\"\\u003e\\u003ca href\\u003d\\"javascript: showAddContainerDialog(\\u0027splitBody0\\u0027);\\" title\\u003d\\"Add Container\\"\\u003e\\u003cspan class\\u003d\\"plusBlueIcon\\"\\u003e\\u003c/span\\u003eAdd Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cspan class\\u003d\\"titleContainerSpan\\" id\\u003d\\"splitBody0_span_5a07f889-4536-4956-aa6e-e7967969ec3f_1567007125001\\" title\\u003d\\"container_5a07f889-4536-4956-aa6e-e7967969ec3f\\"\\u003e\\u003cdiv class\\u003d\\"removeDiv\\"\\u003e\\u003ca href\\u003d\\"javascript: removeDrawedContainer(\\u0027splitBody0\\u0027,\\u00275a07f889-4536-4956-aa6e-e7967969ec3f\\u0027,\\u00271567007125001\\u0027);\\" title\\u003d\\"Remove Container\\"\\u003e\\u003cspan class\\u003d\\"minusIcon\\"\\u003e\\u003c/span\\u003eRemove Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"clear\\"\\u003e\\u003c/div\\u003e\\u003ch2\\u003eContainer: Banner\\u003c/h2\\u003e\\u003cp\\u003eLorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\\u003c/p\\u003e\\u003c/span\\u003e\\u003cdiv style\\u003d\\"display: none;\\" title\\u003d\\"container_5a07f889-4536-4956-aa6e-e7967969ec3f\\" id\\u003d\\"splitBody0_div_5a07f889-4536-4956-aa6e-e7967969ec3f_1567007125001\\"\\u003e#parseContainer(\\u00275a07f889-4536-4956-aa6e-e7967969ec3f\\u0027,\\u00271567007125001\\u0027)\\r\\n\\u003c/div\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody1\\"\\u003e\\u003cdiv class\\u003d\\"yui-g-template\\" id\\u003d\\"yui-g-template\\"\\u003e\\u003cdiv class\\u003d\\"yui-u-template first\\" id\\u003d\\"1_yui-u-grid-1\\"\\u003e\\u003cdiv class\\u003d\\"addContainerSpan\\"\\u003e\\u003ca href\\u003d\\"javascript: showAddContainerDialog(\\u00271_yui-u-grid-1\\u0027);\\" title\\u003d\\"Add Container\\"\\u003e\\u003cspan class\\u003d\\"plusBlueIcon\\"\\u003e\\u003c/span\\u003eAdd Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cspan class\\u003d\\"titleContainerSpan\\" id\\u003d\\"1_yui-u-grid-1_span_69b3d24d-7e80-4be6-b04a-d352d16493ee_1567007147855\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\"\\u003e\\u003cdiv class\\u003d\\"removeDiv\\"\\u003e\\u003ca href\\u003d\\"javascript: removeDrawedContainer(\\u00271_yui-u-grid-1\\u0027,\\u002769b3d24d-7e80-4be6-b04a-d352d16493ee\\u0027,\\u00271567007147855\\u0027);\\" title\\u003d\\"Remove Container\\"\\u003e\\u003cspan class\\u003d\\"minusIcon\\"\\u003e\\u003c/span\\u003eRemove Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"clear\\"\\u003e\\u003c/div\\u003e\\u003ch2\\u003eContainer: Default\\u003c/h2\\u003e\\u003cp\\u003eLorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\\u003c/p\\u003e\\u003c/span\\u003e\\u003cdiv style\\u003d\\"display: none;\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\" id\\u003d\\"1_yui-u-grid-1_div_69b3d24d-7e80-4be6-b04a-d352d16493ee_1567007147855\\"\\u003e#parseContainer(\\u002769b3d24d-7e80-4be6-b04a-d352d16493ee\\u0027,\\u00271567007147855\\u0027)\\r\\n\\u003c/div\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"yui-u-template\\" id\\u003d\\"1_yui-u-grid-2\\"\\u003e\\u003cdiv class\\u003d\\"addContainerSpan\\"\\u003e\\u003ca href\\u003d\\"javascript: showAddContainerDialog(\\u00271_yui-u-grid-2\\u0027);\\" title\\u003d\\"Add Container\\"\\u003e\\u003cspan class\\u003d\\"plusBlueIcon\\"\\u003e\\u003c/span\\u003eAdd Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cspan class\\u003d\\"titleContainerSpan\\" id\\u003d\\"1_yui-u-grid-2_span_69b3d24d-7e80-4be6-b04a-d352d16493ee_1567007153936\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\"\\u003e\\u003cdiv class\\u003d\\"removeDiv\\"\\u003e\\u003ca href\\u003d\\"javascript: removeDrawedContainer(\\u00271_yui-u-grid-2\\u0027,\\u002769b3d24d-7e80-4be6-b04a-d352d16493ee\\u0027,\\u00271567007153936\\u0027);\\" title\\u003d\\"Remove Container\\"\\u003e\\u003cspan class\\u003d\\"minusIcon\\"\\u003e\\u003c/span\\u003eRemove Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"clear\\"\\u003e\\u003c/div\\u003e\\u003ch2\\u003eContainer: Default\\u003c/h2\\u003e\\u003cp\\u003eLorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\\u003c/p\\u003e\\u003c/span\\u003e\\u003cdiv style\\u003d\\"display: none;\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\" id\\u003d\\"1_yui-u-grid-2_div_69b3d24d-7e80-4be6-b04a-d352d16493ee_1567007153936\\"\\u003e#parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271567007153936\\u0027)\\r\\n\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody3\\"\\u003e\\u003cdiv class\\u003d\\"addContainerSpan\\"\\u003e\\u003ca href\\u003d\\"javascript: showAddContainerDialog(\\u0027splitBody3\\u0027);\\" title\\u003d\\"Add Container\\"\\u003e\\u003cspan class\\u003d\\"plusBlueIcon\\"\\u003e\\u003c/span\\u003eAdd Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cspan class\\u003d\\"titleContainerSpan\\" id\\u003d\\"splitBody3_span_69b3d24d-7e80-4be6-b04a-d352d16493ee_1567007193334\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\"\\u003e\\u003cdiv class\\u003d\\"removeDiv\\"\\u003e\\u003ca href\\u003d\\"javascript: removeDrawedContainer(\\u0027splitBody3\\u0027,\\u002769b3d24d-7e80-4be6-b04a-d352d16493ee\\u0027,\\u00271567007193334\\u0027);\\" title\\u003d\\"Remove Container\\"\\u003e\\u003cspan class\\u003d\\"minusIcon\\"\\u003e\\u003c/span\\u003eRemove Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"clear\\"\\u003e\\u003c/div\\u003e\\u003ch2\\u003eContainer: Default\\u003c/h2\\u003e\\u003cp\\u003eLorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\\u003c/p\\u003e\\u003c/span\\u003e\\u003cdiv style\\u003d\\"display: none;\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\" id\\u003d\\"splitBody3_div_69b3d24d-7e80-4be6-b04a-d352d16493ee_1567007193334\\"\\u003e#parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271567007193334\\u0027)\\r\\n\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003cdiv id\\u003d\\"ft-template\\"\\u003e\\u003ch1\\u003eFooter\\u003c/h1\\u003e\\u003c/div\\u003e\\u003c/div\\u003e","countAddContainer":0,"countContainers":0,"theme":"d7b0ebc2-37ca-4a5a-b769-e8a3ff187661","source":"DB","title":"Destination","friendlyName":"Resort Destination Landing Page","modDate":1585198151489,"modUser":"dotcms.org.1","sortOrder":0,"showOnMenu":true,"iDate":1571781392715,"type":"template","inode":"75bfe924-3a59-4cff-aa59-2b9b00a20efe","identifier":"c634d093-c97d-4c37-9004-1262b4578c3e"}}	1585198151489	e64a5620-9bd4-4e08-a53a-67a80079eea1
c8646584-7056-4b59-b630-61497e2a53d0	UN_PUBLISH_LINK	{"type":"com.dotmarketing.portlets.templates.model.Template","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"PERMISSION","visibilityValue":1,"visibilityType":"java.lang.Integer"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"body":"## Container: Blank Container\\r\\n## This is autogenerated code that cannot be changed\\r\\n#parseContainer(\\u0027d71d56b4-0a8b-4bb2-be15-ffa5a23366ea\\u0027,\\u00271539784124854\\u0027)\\r\\n","image":"21ea6da6-68d0-48db-bce8-d1691abd6314","drawed":false,"countAddContainer":0,"countContainers":0,"source":"DB","title":"Blank","friendlyName":"Blank template (No: header, footer, javascript or css)","modDate":1585198153673,"modUser":"dotcms.org.1","sortOrder":0,"showOnMenu":true,"iDate":1570214794641,"type":"template","inode":"9d11b327-9bf5-4d42-92bd-7894d56ed218","identifier":"7acdb856-4bbc-41c5-8695-a39c2e4a913f"}}	1585198153674	e64a5620-9bd4-4e08-a53a-67a80079eea1
31b9265f-4804-4e87-989c-6c9c18d25e27	ARCHIVE_LINK	{"type":"com.dotmarketing.portlets.templates.model.Template","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"PERMISSION","visibilityValue":1,"visibilityType":"java.lang.Integer"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"body":"## Container: Blank Container\\r\\n## This is autogenerated code that cannot be changed\\r\\n#parseContainer(\\u0027d71d56b4-0a8b-4bb2-be15-ffa5a23366ea\\u0027,\\u00271539784124854\\u0027)\\r\\n","image":"21ea6da6-68d0-48db-bce8-d1691abd6314","drawed":false,"countAddContainer":0,"countContainers":0,"source":"DB","title":"Blank","friendlyName":"Blank template (No: header, footer, javascript or css)","modDate":1585198167304,"modUser":"dotcms.org.1","sortOrder":0,"showOnMenu":true,"iDate":1570214794641,"type":"template","inode":"9d11b327-9bf5-4d42-92bd-7894d56ed218","identifier":"7acdb856-4bbc-41c5-8695-a39c2e4a913f"}}	1585198167305	e64a5620-9bd4-4e08-a53a-67a80079eea1
5e16d245-05a7-4882-b136-f0532e33c442	ARCHIVE_LINK	{"type":"com.dotmarketing.portlets.templates.model.Template","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"PERMISSION","visibilityValue":1,"visibilityType":"java.lang.Integer"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"body":"\\u003chtml\\u003e\\n \\u003chead\\u003e\\n  #dotParse(\\u0027//starter.dotcms.com/application/themes/travel/html_head.vtl\\u0027)\\n  \\u003clink rel\\u003d\\"stylesheet\\" type\\u003d\\"text/css\\" href\\u003d\\"/html/css/template/reset-fonts-grids.css\\" /\\u003e\\n \\u003c/head\\u003e\\n \\u003cbody\\u003e\\n  \\u003cdiv id\\u003d\\"resp-template\\" name\\u003d\\"globalContainer\\"\\u003e\\n   \\u003cdiv id\\u003d\\"hd-template\\"\\u003e\\n    #dotParse(\\u0027//starter.dotcms.com/application/themes/travel/header.vtl\\u0027)\\n   \\u003c/div\\u003e\\n   \\u003cdiv id\\u003d\\"bd-template\\"\\u003e\\n    \\u003cdiv id\\u003d\\"yui-main-template\\"\\u003e\\n     \\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody0\\"\\u003e\\n      #parseContainer(\\u00275a07f889-4536-4956-aa6e-e7967969ec3f\\u0027,\\u00271567007125001\\u0027)\\n     \\u003c/div\\u003e\\n     \\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody1\\"\\u003e\\n      \\u003cdiv class\\u003d\\"yui-g-template\\" id\\u003d\\"yui-g-template\\"\\u003e\\n       \\u003cdiv class\\u003d\\"yui-u-template first\\" id\\u003d\\"1_yui-u-grid-1\\"\\u003e\\n        #parseContainer(\\u002769b3d24d-7e80-4be6-b04a-d352d16493ee\\u0027,\\u00271567007147855\\u0027)\\n       \\u003c/div\\u003e\\n       \\u003cdiv class\\u003d\\"yui-u-template\\" id\\u003d\\"1_yui-u-grid-2\\"\\u003e\\n        #parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271567007153936\\u0027)\\n       \\u003c/div\\u003e\\n      \\u003c/div\\u003e\\n     \\u003c/div\\u003e\\n     \\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody3\\"\\u003e\\n      #parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271567007193334\\u0027)\\n     \\u003c/div\\u003e\\n    \\u003c/div\\u003e\\n   \\u003c/div\\u003e\\n   \\u003cdiv id\\u003d\\"ft-template\\"\\u003e\\n    #dotParse(\\u0027//starter.dotcms.com/application/themes/travel/footer.vtl\\u0027)\\n   \\u003c/div\\u003e\\n  \\u003c/div\\u003e\\n \\u003c/body\\u003e\\n\\u003c/html\\u003e","image":"","drawed":true,"drawedBody":"\\u003cdiv id\\u003d\\"resp-template\\" name\\u003d\\"globalContainer\\"\\u003e\\u003cdiv id\\u003d\\"hd-template\\"\\u003e\\u003ch1\\u003eHeader\\u003c/h1\\u003e\\u003c/div\\u003e\\u003cdiv id\\u003d\\"bd-template\\"\\u003e\\u003cdiv id\\u003d\\"yui-main-template\\"\\u003e\\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody0\\"\\u003e\\u003cdiv class\\u003d\\"addContainerSpan\\"\\u003e\\u003ca href\\u003d\\"javascript: showAddContainerDialog(\\u0027splitBody0\\u0027);\\" title\\u003d\\"Add Container\\"\\u003e\\u003cspan class\\u003d\\"plusBlueIcon\\"\\u003e\\u003c/span\\u003eAdd Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cspan class\\u003d\\"titleContainerSpan\\" id\\u003d\\"splitBody0_span_5a07f889-4536-4956-aa6e-e7967969ec3f_1567007125001\\" title\\u003d\\"container_5a07f889-4536-4956-aa6e-e7967969ec3f\\"\\u003e\\u003cdiv class\\u003d\\"removeDiv\\"\\u003e\\u003ca href\\u003d\\"javascript: removeDrawedContainer(\\u0027splitBody0\\u0027,\\u00275a07f889-4536-4956-aa6e-e7967969ec3f\\u0027,\\u00271567007125001\\u0027);\\" title\\u003d\\"Remove Container\\"\\u003e\\u003cspan class\\u003d\\"minusIcon\\"\\u003e\\u003c/span\\u003eRemove Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"clear\\"\\u003e\\u003c/div\\u003e\\u003ch2\\u003eContainer: Banner\\u003c/h2\\u003e\\u003cp\\u003eLorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\\u003c/p\\u003e\\u003c/span\\u003e\\u003cdiv style\\u003d\\"display: none;\\" title\\u003d\\"container_5a07f889-4536-4956-aa6e-e7967969ec3f\\" id\\u003d\\"splitBody0_div_5a07f889-4536-4956-aa6e-e7967969ec3f_1567007125001\\"\\u003e#parseContainer(\\u00275a07f889-4536-4956-aa6e-e7967969ec3f\\u0027,\\u00271567007125001\\u0027)\\r\\n\\u003c/div\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody1\\"\\u003e\\u003cdiv class\\u003d\\"yui-g-template\\" id\\u003d\\"yui-g-template\\"\\u003e\\u003cdiv class\\u003d\\"yui-u-template first\\" id\\u003d\\"1_yui-u-grid-1\\"\\u003e\\u003cdiv class\\u003d\\"addContainerSpan\\"\\u003e\\u003ca href\\u003d\\"javascript: showAddContainerDialog(\\u00271_yui-u-grid-1\\u0027);\\" title\\u003d\\"Add Container\\"\\u003e\\u003cspan class\\u003d\\"plusBlueIcon\\"\\u003e\\u003c/span\\u003eAdd Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cspan class\\u003d\\"titleContainerSpan\\" id\\u003d\\"1_yui-u-grid-1_span_69b3d24d-7e80-4be6-b04a-d352d16493ee_1567007147855\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\"\\u003e\\u003cdiv class\\u003d\\"removeDiv\\"\\u003e\\u003ca href\\u003d\\"javascript: removeDrawedContainer(\\u00271_yui-u-grid-1\\u0027,\\u002769b3d24d-7e80-4be6-b04a-d352d16493ee\\u0027,\\u00271567007147855\\u0027);\\" title\\u003d\\"Remove Container\\"\\u003e\\u003cspan class\\u003d\\"minusIcon\\"\\u003e\\u003c/span\\u003eRemove Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"clear\\"\\u003e\\u003c/div\\u003e\\u003ch2\\u003eContainer: Default\\u003c/h2\\u003e\\u003cp\\u003eLorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\\u003c/p\\u003e\\u003c/span\\u003e\\u003cdiv style\\u003d\\"display: none;\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\" id\\u003d\\"1_yui-u-grid-1_div_69b3d24d-7e80-4be6-b04a-d352d16493ee_1567007147855\\"\\u003e#parseContainer(\\u002769b3d24d-7e80-4be6-b04a-d352d16493ee\\u0027,\\u00271567007147855\\u0027)\\r\\n\\u003c/div\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"yui-u-template\\" id\\u003d\\"1_yui-u-grid-2\\"\\u003e\\u003cdiv class\\u003d\\"addContainerSpan\\"\\u003e\\u003ca href\\u003d\\"javascript: showAddContainerDialog(\\u00271_yui-u-grid-2\\u0027);\\" title\\u003d\\"Add Container\\"\\u003e\\u003cspan class\\u003d\\"plusBlueIcon\\"\\u003e\\u003c/span\\u003eAdd Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cspan class\\u003d\\"titleContainerSpan\\" id\\u003d\\"1_yui-u-grid-2_span_69b3d24d-7e80-4be6-b04a-d352d16493ee_1567007153936\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\"\\u003e\\u003cdiv class\\u003d\\"removeDiv\\"\\u003e\\u003ca href\\u003d\\"javascript: removeDrawedContainer(\\u00271_yui-u-grid-2\\u0027,\\u002769b3d24d-7e80-4be6-b04a-d352d16493ee\\u0027,\\u00271567007153936\\u0027);\\" title\\u003d\\"Remove Container\\"\\u003e\\u003cspan class\\u003d\\"minusIcon\\"\\u003e\\u003c/span\\u003eRemove Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"clear\\"\\u003e\\u003c/div\\u003e\\u003ch2\\u003eContainer: Default\\u003c/h2\\u003e\\u003cp\\u003eLorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\\u003c/p\\u003e\\u003c/span\\u003e\\u003cdiv style\\u003d\\"display: none;\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\" id\\u003d\\"1_yui-u-grid-2_div_69b3d24d-7e80-4be6-b04a-d352d16493ee_1567007153936\\"\\u003e#parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271567007153936\\u0027)\\r\\n\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody3\\"\\u003e\\u003cdiv class\\u003d\\"addContainerSpan\\"\\u003e\\u003ca href\\u003d\\"javascript: showAddContainerDialog(\\u0027splitBody3\\u0027);\\" title\\u003d\\"Add Container\\"\\u003e\\u003cspan class\\u003d\\"plusBlueIcon\\"\\u003e\\u003c/span\\u003eAdd Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cspan class\\u003d\\"titleContainerSpan\\" id\\u003d\\"splitBody3_span_69b3d24d-7e80-4be6-b04a-d352d16493ee_1567007193334\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\"\\u003e\\u003cdiv class\\u003d\\"removeDiv\\"\\u003e\\u003ca href\\u003d\\"javascript: removeDrawedContainer(\\u0027splitBody3\\u0027,\\u002769b3d24d-7e80-4be6-b04a-d352d16493ee\\u0027,\\u00271567007193334\\u0027);\\" title\\u003d\\"Remove Container\\"\\u003e\\u003cspan class\\u003d\\"minusIcon\\"\\u003e\\u003c/span\\u003eRemove Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"clear\\"\\u003e\\u003c/div\\u003e\\u003ch2\\u003eContainer: Default\\u003c/h2\\u003e\\u003cp\\u003eLorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\\u003c/p\\u003e\\u003c/span\\u003e\\u003cdiv style\\u003d\\"display: none;\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\" id\\u003d\\"splitBody3_div_69b3d24d-7e80-4be6-b04a-d352d16493ee_1567007193334\\"\\u003e#parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271567007193334\\u0027)\\r\\n\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003cdiv id\\u003d\\"ft-template\\"\\u003e\\u003ch1\\u003eFooter\\u003c/h1\\u003e\\u003c/div\\u003e\\u003c/div\\u003e","countAddContainer":0,"countContainers":0,"theme":"d7b0ebc2-37ca-4a5a-b769-e8a3ff187661","source":"DB","title":"Destination","friendlyName":"Resort Destination Landing Page","modDate":1585198169953,"modUser":"dotcms.org.1","sortOrder":0,"showOnMenu":true,"iDate":1571781392715,"type":"template","inode":"75bfe924-3a59-4cff-aa59-2b9b00a20efe","identifier":"c634d093-c97d-4c37-9004-1262b4578c3e"}}	1585198169955	e64a5620-9bd4-4e08-a53a-67a80079eea1
b10df3ae-d347-4fba-8511-f8ca74eaa123	ARCHIVE_LINK	{"type":"com.dotmarketing.portlets.templates.model.Template","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"PERMISSION","visibilityValue":1,"visibilityType":"java.lang.Integer"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"body":"\\u003chtml\\u003e\\n \\u003chead\\u003e\\n  #dotParse(\\u0027//starter.dotcms.com/application/themes/landing-page/html_head.vtl\\u0027)\\n  \\u003clink rel\\u003d\\"stylesheet\\" type\\u003d\\"text/css\\" href\\u003d\\"/html/css/template/reset-fonts-grids.css\\" /\\u003e\\n \\u003c/head\\u003e\\n \\u003cbody\\u003e\\n  \\u003cdiv id\\u003d\\"resp-template\\" name\\u003d\\"globalContainer\\"\\u003e\\n   \\u003cdiv id\\u003d\\"hd-template\\"\\u003e\\n    #dotParse(\\u0027//starter.dotcms.com/application/themes/landing-page/header.vtl\\u0027)\\n   \\u003c/div\\u003e\\n   \\u003cdiv id\\u003d\\"bd-template\\"\\u003e\\n    \\u003cdiv id\\u003d\\"yui-main-template\\"\\u003e\\n     \\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody0\\"\\u003e\\n      \\u003cdiv class\\u003d\\"yui-g-template\\" id\\u003d\\"yui-g-template\\"\\u003e\\n       \\u003cdiv class\\u003d\\"yui-u-template first\\" id\\u003d\\"0_yui-u-grid-1\\"\\u003e\\n        #parseContainer(\\u002769b3d24d-7e80-4be6-b04a-d352d16493ee\\u0027,\\u00271570474272766\\u0027)\\n       \\u003c/div\\u003e\\n       \\u003cdiv class\\u003d\\"yui-u-template\\" id\\u003d\\"0_yui-u-grid-2\\"\\u003e\\n        #parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271570474279795\\u0027)\\n       \\u003c/div\\u003e\\n      \\u003c/div\\u003e\\n     \\u003c/div\\u003e\\n     \\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody1\\"\\u003e\\n      \\u003cdiv class\\u003d\\"yui-g-template\\" id\\u003d\\"yui-g-template\\"\\u003e\\n       \\u003cdiv class\\u003d\\"yui-u-template first\\" id\\u003d\\"1_yui-u-grid-1\\"\\u003e\\n        #parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271569962310124\\u0027)\\n       \\u003c/div\\u003e\\n       \\u003cdiv class\\u003d\\"yui-u-template\\" id\\u003d\\"1_yui-u-grid-2\\"\\u003e\\n        #parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271569962338553\\u0027)\\n       \\u003c/div\\u003e\\n      \\u003c/div\\u003e\\n     \\u003c/div\\u003e\\n     \\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody2\\"\\u003e\\n      \\u003cdiv class\\u003d\\"yui-g-template\\" id\\u003d\\"yui-js-template\\"\\u003e\\n       \\u003cdiv class\\u003d\\"yui-g-template\\" id\\u003d\\"yui-g-template\\"\\u003e\\n        \\u003cdiv class\\u003d\\"yui-u-template first\\" id\\u003d\\"2_yui-u-grid-1\\"\\u003e\\n         #parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271569962351862\\u0027)\\n        \\u003c/div\\u003e\\n        \\u003cdiv class\\u003d\\"yui-u-template\\" id\\u003d\\"2_yui-u-grid-2\\"\\u003e\\n         #parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271569962355912\\u0027)\\n        \\u003c/div\\u003e\\n       \\u003c/div\\u003e\\n       \\u003cdiv class\\u003d\\"yui-g-template\\" id\\u003d\\"yui-g-template\\" style\\u003d\\"margin-left:10px\\"\\u003e\\n        \\u003cdiv class\\u003d\\"yui-u-template first\\" id\\u003d\\"2_yui-u-grid-3\\"\\u003e\\n         #parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271569962359713\\u0027)\\n        \\u003c/div\\u003e\\n        \\u003cdiv class\\u003d\\"yui-u-template\\" id\\u003d\\"2_yui-u-grid-4\\"\\u003e\\n         #parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271569962363832\\u0027)\\n        \\u003c/div\\u003e\\n       \\u003c/div\\u003e\\n      \\u003c/div\\u003e\\n     \\u003c/div\\u003e\\n     \\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody3\\"\\u003e\\n      #parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271569962376026\\u0027)\\n     \\u003c/div\\u003e\\n    \\u003c/div\\u003e\\n   \\u003c/div\\u003e\\n   \\u003cdiv id\\u003d\\"ft-template\\"\\u003e\\n    #dotParse(\\u0027//starter.dotcms.com/application/themes/landing-page/footer.vtl\\u0027)\\n   \\u003c/div\\u003e\\n  \\u003c/div\\u003e\\n \\u003c/body\\u003e\\n\\u003c/html\\u003e","image":"cf7968a1-59be-4ca3-a744-5401d6c68c53","drawed":true,"drawedBody":"\\u003cdiv id\\u003d\\"resp-template\\" name\\u003d\\"globalContainer\\"\\u003e\\u003cdiv id\\u003d\\"hd-template\\"\\u003e\\u003ch1\\u003eHeader\\u003c/h1\\u003e\\u003c/div\\u003e\\u003cdiv id\\u003d\\"bd-template\\"\\u003e\\u003cdiv id\\u003d\\"yui-main-template\\"\\u003e\\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody0\\"\\u003e\\u003cdiv class\\u003d\\"yui-g-template\\" id\\u003d\\"yui-g-template\\"\\u003e\\u003cdiv class\\u003d\\"yui-u-template first\\" id\\u003d\\"0_yui-u-grid-1\\"\\u003e\\u003cdiv class\\u003d\\"addContainerSpan\\"\\u003e\\u003ca href\\u003d\\"javascript: showAddContainerDialog(\\u00270_yui-u-grid-1\\u0027);\\" title\\u003d\\"Add Container\\"\\u003e\\u003cspan class\\u003d\\"plusBlueIcon\\"\\u003e\\u003c/span\\u003eAdd Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cspan class\\u003d\\"titleContainerSpan\\" id\\u003d\\"0_yui-u-grid-1_span_69b3d24d-7e80-4be6-b04a-d352d16493ee_1570474272766\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\"\\u003e\\u003cdiv class\\u003d\\"removeDiv\\"\\u003e\\u003ca href\\u003d\\"javascript: removeDrawedContainer(\\u00270_yui-u-grid-1\\u0027,\\u002769b3d24d-7e80-4be6-b04a-d352d16493ee\\u0027,\\u00271570474272766\\u0027);\\" title\\u003d\\"Remove Container\\"\\u003e\\u003cspan class\\u003d\\"minusIcon\\"\\u003e\\u003c/span\\u003eRemove Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"clear\\"\\u003e\\u003c/div\\u003e\\u003ch2\\u003eContainer: Default\\u003c/h2\\u003e\\u003cp\\u003eLorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\\u003c/p\\u003e\\u003c/span\\u003e\\u003cdiv style\\u003d\\"display: none;\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\" id\\u003d\\"0_yui-u-grid-1_div_69b3d24d-7e80-4be6-b04a-d352d16493ee_1570474272766\\"\\u003e#parseContainer(\\u002769b3d24d-7e80-4be6-b04a-d352d16493ee\\u0027,\\u00271570474272766\\u0027)\\r\\n\\u003c/div\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"yui-u-template\\" id\\u003d\\"0_yui-u-grid-2\\"\\u003e\\u003cdiv class\\u003d\\"addContainerSpan\\"\\u003e\\u003ca href\\u003d\\"javascript: showAddContainerDialog(\\u00270_yui-u-grid-2\\u0027);\\" title\\u003d\\"Add Container\\"\\u003e\\u003cspan class\\u003d\\"plusBlueIcon\\"\\u003e\\u003c/span\\u003eAdd Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cspan class\\u003d\\"titleContainerSpan\\" id\\u003d\\"0_yui-u-grid-2_span_69b3d24d-7e80-4be6-b04a-d352d16493ee_1570474279795\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\"\\u003e\\u003cdiv class\\u003d\\"removeDiv\\"\\u003e\\u003ca href\\u003d\\"javascript: removeDrawedContainer(\\u00270_yui-u-grid-2\\u0027,\\u002769b3d24d-7e80-4be6-b04a-d352d16493ee\\u0027,\\u00271570474279795\\u0027);\\" title\\u003d\\"Remove Container\\"\\u003e\\u003cspan class\\u003d\\"minusIcon\\"\\u003e\\u003c/span\\u003eRemove Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"clear\\"\\u003e\\u003c/div\\u003e\\u003ch2\\u003eContainer: Default\\u003c/h2\\u003e\\u003cp\\u003eLorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\\u003c/p\\u003e\\u003c/span\\u003e\\u003cdiv style\\u003d\\"display: none;\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\" id\\u003d\\"0_yui-u-grid-2_div_69b3d24d-7e80-4be6-b04a-d352d16493ee_1570474279795\\"\\u003e#parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271570474279795\\u0027)\\r\\n\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody1\\"\\u003e\\u003cdiv class\\u003d\\"yui-g-template\\" id\\u003d\\"yui-g-template\\"\\u003e\\u003cdiv class\\u003d\\"yui-u-template first\\" id\\u003d\\"1_yui-u-grid-1\\"\\u003e\\u003cdiv class\\u003d\\"addContainerSpan\\"\\u003e\\u003ca href\\u003d\\"javascript: showAddContainerDialog(\\u00271_yui-u-grid-1\\u0027);\\" title\\u003d\\"Add Container\\"\\u003e\\u003cspan class\\u003d\\"plusBlueIcon\\"\\u003e\\u003c/span\\u003eAdd Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cspan class\\u003d\\"titleContainerSpan\\" id\\u003d\\"1_yui-u-grid-1_span_69b3d24d-7e80-4be6-b04a-d352d16493ee_1569962310124\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\"\\u003e\\u003cdiv class\\u003d\\"removeDiv\\"\\u003e\\u003ca href\\u003d\\"javascript: removeDrawedContainer(\\u00271_yui-u-grid-1\\u0027,\\u002769b3d24d-7e80-4be6-b04a-d352d16493ee\\u0027,\\u00271569962310124\\u0027);\\" title\\u003d\\"Remove Container\\"\\u003e\\u003cspan class\\u003d\\"minusIcon\\"\\u003e\\u003c/span\\u003eRemove Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"clear\\"\\u003e\\u003c/div\\u003e\\u003ch2\\u003eContainer: Default\\u003c/h2\\u003e\\u003cp\\u003eLorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\\u003c/p\\u003e\\u003c/span\\u003e\\u003cdiv style\\u003d\\"display: none;\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\" id\\u003d\\"1_yui-u-grid-1_div_69b3d24d-7e80-4be6-b04a-d352d16493ee_1569962310124\\"\\u003e#parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271569962310124\\u0027)\\r\\n\\u003c/div\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"yui-u-template\\" id\\u003d\\"1_yui-u-grid-2\\"\\u003e\\u003cdiv class\\u003d\\"addContainerSpan\\"\\u003e\\u003ca href\\u003d\\"javascript: showAddContainerDialog(\\u00271_yui-u-grid-2\\u0027);\\" title\\u003d\\"Add Container\\"\\u003e\\u003cspan class\\u003d\\"plusBlueIcon\\"\\u003e\\u003c/span\\u003eAdd Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cspan class\\u003d\\"titleContainerSpan\\" id\\u003d\\"1_yui-u-grid-2_span_69b3d24d-7e80-4be6-b04a-d352d16493ee_1569962338553\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\"\\u003e\\u003cdiv class\\u003d\\"removeDiv\\"\\u003e\\u003ca href\\u003d\\"javascript: removeDrawedContainer(\\u00271_yui-u-grid-2\\u0027,\\u002769b3d24d-7e80-4be6-b04a-d352d16493ee\\u0027,\\u00271569962338553\\u0027);\\" title\\u003d\\"Remove Container\\"\\u003e\\u003cspan class\\u003d\\"minusIcon\\"\\u003e\\u003c/span\\u003eRemove Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"clear\\"\\u003e\\u003c/div\\u003e\\u003ch2\\u003eContainer: Default\\u003c/h2\\u003e\\u003cp\\u003eLorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\\u003c/p\\u003e\\u003c/span\\u003e\\u003cdiv style\\u003d\\"display: none;\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\" id\\u003d\\"1_yui-u-grid-2_div_69b3d24d-7e80-4be6-b04a-d352d16493ee_1569962338553\\"\\u003e#parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271569962338553\\u0027)\\r\\n\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody2\\"\\u003e\\u003cdiv class\\u003d\\"yui-g-template\\" id\\u003d\\"yui-js-template\\"\\u003e\\u003cdiv class\\u003d\\"yui-g-template\\" id\\u003d\\"yui-g-template\\"\\u003e\\u003cdiv class\\u003d\\"yui-u-template first\\" id\\u003d\\"2_yui-u-grid-1\\"\\u003e\\u003cdiv class\\u003d\\"addContainerSpan\\"\\u003e\\u003ca href\\u003d\\"javascript: showAddContainerDialog(\\u00272_yui-u-grid-1\\u0027);\\" title\\u003d\\"Add Container\\"\\u003e\\u003cspan class\\u003d\\"plusBlueIcon\\"\\u003e\\u003c/span\\u003eAdd Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cspan class\\u003d\\"titleContainerSpan\\" id\\u003d\\"2_yui-u-grid-1_span_69b3d24d-7e80-4be6-b04a-d352d16493ee_1569962351862\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\"\\u003e\\u003cdiv class\\u003d\\"removeDiv\\"\\u003e\\u003ca href\\u003d\\"javascript: removeDrawedContainer(\\u00272_yui-u-grid-1\\u0027,\\u002769b3d24d-7e80-4be6-b04a-d352d16493ee\\u0027,\\u00271569962351862\\u0027);\\" title\\u003d\\"Remove Container\\"\\u003e\\u003cspan class\\u003d\\"minusIcon\\"\\u003e\\u003c/span\\u003eRemove Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"clear\\"\\u003e\\u003c/div\\u003e\\u003ch2\\u003eContainer: Default\\u003c/h2\\u003e\\u003cp\\u003eLorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\\u003c/p\\u003e\\u003c/span\\u003e\\u003cdiv style\\u003d\\"display: none;\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\" id\\u003d\\"2_yui-u-grid-1_div_69b3d24d-7e80-4be6-b04a-d352d16493ee_1569962351862\\"\\u003e#parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271569962351862\\u0027)\\r\\n\\u003c/div\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"yui-u-template\\" id\\u003d\\"2_yui-u-grid-2\\"\\u003e\\u003cdiv class\\u003d\\"addContainerSpan\\"\\u003e\\u003ca href\\u003d\\"javascript: showAddContainerDialog(\\u00272_yui-u-grid-2\\u0027);\\" title\\u003d\\"Add Container\\"\\u003e\\u003cspan class\\u003d\\"plusBlueIcon\\"\\u003e\\u003c/span\\u003eAdd Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cspan class\\u003d\\"titleContainerSpan\\" id\\u003d\\"2_yui-u-grid-2_span_69b3d24d-7e80-4be6-b04a-d352d16493ee_1569962355912\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\"\\u003e\\u003cdiv class\\u003d\\"removeDiv\\"\\u003e\\u003ca href\\u003d\\"javascript: removeDrawedContainer(\\u00272_yui-u-grid-2\\u0027,\\u002769b3d24d-7e80-4be6-b04a-d352d16493ee\\u0027,\\u00271569962355912\\u0027);\\" title\\u003d\\"Remove Container\\"\\u003e\\u003cspan class\\u003d\\"minusIcon\\"\\u003e\\u003c/span\\u003eRemove Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"clear\\"\\u003e\\u003c/div\\u003e\\u003ch2\\u003eContainer: Default\\u003c/h2\\u003e\\u003cp\\u003eLorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\\u003c/p\\u003e\\u003c/span\\u003e\\u003cdiv style\\u003d\\"display: none;\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\" id\\u003d\\"2_yui-u-grid-2_div_69b3d24d-7e80-4be6-b04a-d352d16493ee_1569962355912\\"\\u003e#parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271569962355912\\u0027)\\r\\n\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"yui-g-template\\" id\\u003d\\"yui-g-template\\" style\\u003d\\"margin-left:10px\\"\\u003e\\u003cdiv class\\u003d\\"yui-u-template first\\" id\\u003d\\"2_yui-u-grid-3\\"\\u003e\\u003cdiv class\\u003d\\"addContainerSpan\\"\\u003e\\u003ca href\\u003d\\"javascript: showAddContainerDialog(\\u00272_yui-u-grid-3\\u0027);\\" title\\u003d\\"Add Container\\"\\u003e\\u003cspan class\\u003d\\"plusBlueIcon\\"\\u003e\\u003c/span\\u003eAdd Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cspan class\\u003d\\"titleContainerSpan\\" id\\u003d\\"2_yui-u-grid-3_span_69b3d24d-7e80-4be6-b04a-d352d16493ee_1569962359713\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\"\\u003e\\u003cdiv class\\u003d\\"removeDiv\\"\\u003e\\u003ca href\\u003d\\"javascript: removeDrawedContainer(\\u00272_yui-u-grid-3\\u0027,\\u002769b3d24d-7e80-4be6-b04a-d352d16493ee\\u0027,\\u00271569962359713\\u0027);\\" title\\u003d\\"Remove Container\\"\\u003e\\u003cspan class\\u003d\\"minusIcon\\"\\u003e\\u003c/span\\u003eRemove Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"clear\\"\\u003e\\u003c/div\\u003e\\u003ch2\\u003eContainer: Default\\u003c/h2\\u003e\\u003cp\\u003eLorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\\u003c/p\\u003e\\u003c/span\\u003e\\u003cdiv style\\u003d\\"display: none;\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\" id\\u003d\\"2_yui-u-grid-3_div_69b3d24d-7e80-4be6-b04a-d352d16493ee_1569962359713\\"\\u003e#parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271569962359713\\u0027)\\r\\n\\u003c/div\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"yui-u-template\\" id\\u003d\\"2_yui-u-grid-4\\"\\u003e\\u003cdiv class\\u003d\\"addContainerSpan\\"\\u003e\\u003ca href\\u003d\\"javascript: showAddContainerDialog(\\u00272_yui-u-grid-4\\u0027);\\" title\\u003d\\"Add Container\\"\\u003e\\u003cspan class\\u003d\\"plusBlueIcon\\"\\u003e\\u003c/span\\u003eAdd Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cspan class\\u003d\\"titleContainerSpan\\" id\\u003d\\"2_yui-u-grid-4_span_69b3d24d-7e80-4be6-b04a-d352d16493ee_1569962363832\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\"\\u003e\\u003cdiv class\\u003d\\"removeDiv\\"\\u003e\\u003ca href\\u003d\\"javascript: removeDrawedContainer(\\u00272_yui-u-grid-4\\u0027,\\u002769b3d24d-7e80-4be6-b04a-d352d16493ee\\u0027,\\u00271569962363832\\u0027);\\" title\\u003d\\"Remove Container\\"\\u003e\\u003cspan class\\u003d\\"minusIcon\\"\\u003e\\u003c/span\\u003eRemove Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"clear\\"\\u003e\\u003c/div\\u003e\\u003ch2\\u003eContainer: Default\\u003c/h2\\u003e\\u003cp\\u003eLorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\\u003c/p\\u003e\\u003c/span\\u003e\\u003cdiv style\\u003d\\"display: none;\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\" id\\u003d\\"2_yui-u-grid-4_div_69b3d24d-7e80-4be6-b04a-d352d16493ee_1569962363832\\"\\u003e#parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271569962363832\\u0027)\\r\\n\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody3\\"\\u003e\\u003cdiv class\\u003d\\"addContainerSpan\\"\\u003e\\u003ca href\\u003d\\"javascript: showAddContainerDialog(\\u0027splitBody3\\u0027);\\" title\\u003d\\"Add Container\\"\\u003e\\u003cspan class\\u003d\\"plusBlueIcon\\"\\u003e\\u003c/span\\u003eAdd Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cspan class\\u003d\\"titleContainerSpan\\" id\\u003d\\"splitBody3_span_69b3d24d-7e80-4be6-b04a-d352d16493ee_1569962376026\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\"\\u003e\\u003cdiv class\\u003d\\"removeDiv\\"\\u003e\\u003ca href\\u003d\\"javascript: removeDrawedContainer(\\u0027splitBody3\\u0027,\\u002769b3d24d-7e80-4be6-b04a-d352d16493ee\\u0027,\\u00271569962376026\\u0027);\\" title\\u003d\\"Remove Container\\"\\u003e\\u003cspan class\\u003d\\"minusIcon\\"\\u003e\\u003c/span\\u003eRemove Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"clear\\"\\u003e\\u003c/div\\u003e\\u003ch2\\u003eContainer: Default\\u003c/h2\\u003e\\u003cp\\u003eLorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\\u003c/p\\u003e\\u003c/span\\u003e\\u003cdiv style\\u003d\\"display: none;\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\" id\\u003d\\"splitBody3_div_69b3d24d-7e80-4be6-b04a-d352d16493ee_1569962376026\\"\\u003e#parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271569962376026\\u0027)\\r\\n\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003cdiv id\\u003d\\"ft-template\\"\\u003e\\u003ch1\\u003eFooter\\u003c/h1\\u003e\\u003c/div\\u003e\\u003c/div\\u003e","countAddContainer":0,"countContainers":0,"theme":"ce00bd28-5f66-47f9-96ca-bbf0722a79aa","source":"DB","title":"Landing Page","friendlyName":"Marketing Landing Page","modDate":1585198172420,"modUser":"dotcms.org.1","sortOrder":0,"showOnMenu":true,"iDate":1571781566313,"type":"template","inode":"3a79250a-cd9c-455f-b41c-64a18088cd93","identifier":"fde4c167-edf4-4699-8a3a-0bf155067555"}}	1585198172422	e64a5620-9bd4-4e08-a53a-67a80079eea1
312b2bdc-46a0-4d4d-85fb-90af1285a61d	UN_PUBLISH_LINK	{"type":"com.dotmarketing.portlets.templates.model.Template","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"PERMISSION","visibilityValue":1,"visibilityType":"java.lang.Integer"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"body":"\\u003chtml\\u003e\\n \\u003chead\\u003e\\n  #dotParse(\\u0027//starter.dotcms.com/application/themes/travel/html_head.vtl\\u0027)\\n  \\u003clink rel\\u003d\\"stylesheet\\" type\\u003d\\"text/css\\" href\\u003d\\"/html/css/template/reset-fonts-grids.css\\" /\\u003e\\n \\u003c/head\\u003e\\n \\u003cbody\\u003e\\n  \\u003cdiv id\\u003d\\"resp-template\\" name\\u003d\\"globalContainer\\"\\u003e\\n   \\u003cdiv id\\u003d\\"hd-template\\"\\u003e\\n    #dotParse(\\u0027//starter.dotcms.com/application/themes/travel/header.vtl\\u0027)\\n   \\u003c/div\\u003e\\n   \\u003cdiv id\\u003d\\"bd-template\\"\\u003e\\n    \\u003cdiv id\\u003d\\"yui-main-template\\"\\u003e\\n     \\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody0\\"\\u003e\\n      #parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271562770692396\\u0027)\\n     \\u003c/div\\u003e\\n    \\u003c/div\\u003e\\n   \\u003c/div\\u003e\\n   \\u003cdiv id\\u003d\\"ft-template\\"\\u003e\\n    #dotParse(\\u0027//starter.dotcms.com/application/themes/travel/footer.vtl\\u0027)\\n   \\u003c/div\\u003e\\n  \\u003c/div\\u003e\\n \\u003c/body\\u003e\\n\\u003c/html\\u003e","image":"462ebb90-7f05-4719-8d36-677756be74e1","drawed":true,"drawedBody":"\\u003cdiv id\\u003d\\"resp-template\\" name\\u003d\\"globalContainer\\"\\u003e\\u003cdiv id\\u003d\\"hd-template\\"\\u003e\\u003ch1\\u003eHeader\\u003c/h1\\u003e\\u003c/div\\u003e\\u003cdiv id\\u003d\\"bd-template\\"\\u003e\\u003cdiv id\\u003d\\"yui-main-template\\"\\u003e\\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody0\\"\\u003e\\u003cdiv class\\u003d\\"addContainerSpan\\"\\u003e\\u003ca href\\u003d\\"javascript: showAddContainerDialog(\\u0027splitBody0\\u0027);\\" title\\u003d\\"Add Container\\"\\u003e\\u003cspan class\\u003d\\"plusBlueIcon\\"\\u003e\\u003c/span\\u003eAdd Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cspan class\\u003d\\"titleContainerSpan\\" id\\u003d\\"splitBody0_span_69b3d24d-7e80-4be6-b04a-d352d16493ee_1562770692396\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\"\\u003e\\u003cdiv class\\u003d\\"removeDiv\\"\\u003e\\u003ca href\\u003d\\"javascript: removeDrawedContainer(\\u0027splitBody0\\u0027,\\u002769b3d24d-7e80-4be6-b04a-d352d16493ee\\u0027,\\u00271562770692396\\u0027);\\" title\\u003d\\"Remove Container\\"\\u003e\\u003cspan class\\u003d\\"minusIcon\\"\\u003e\\u003c/span\\u003eRemove Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"clear\\"\\u003e\\u003c/div\\u003e\\u003ch2\\u003eContainer: Default\\u003c/h2\\u003e\\u003cp\\u003eLorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\\u003c/p\\u003e\\u003c/span\\u003e\\u003cdiv style\\u003d\\"display: none;\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\" id\\u003d\\"splitBody0_div_69b3d24d-7e80-4be6-b04a-d352d16493ee_1562770692396\\"\\u003e#parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271562770692396\\u0027)\\r\\n\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003cdiv id\\u003d\\"ft-template\\"\\u003e\\u003ch1\\u003eFooter\\u003c/h1\\u003e\\u003c/div\\u003e\\u003c/div\\u003e","countAddContainer":0,"countContainers":0,"theme":"d7b0ebc2-37ca-4a5a-b769-e8a3ff187661","source":"DB","title":"Default Template","friendlyName":"Default Single Column Template","modDate":1585198155638,"modUser":"dotcms.org.1","sortOrder":0,"showOnMenu":true,"iDate":1567021150494,"type":"template","inode":"316a7de7-7b0e-4322-b925-09f177afd0c2","identifier":"31f4c794-c769-4929-9d5d-7c383408c65c"}}	1585198155639	e64a5620-9bd4-4e08-a53a-67a80079eea1
8e5f8842-546a-4506-bfbe-5d11f5dc7f3e	UN_PUBLISH_LINK	{"type":"com.dotmarketing.portlets.templates.model.Template","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"PERMISSION","visibilityValue":1,"visibilityType":"java.lang.Integer"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"body":"\\u003chtml\\u003e\\n \\u003chead\\u003e\\n  #dotParse(\\u0027//starter.dotcms.com/application/themes/travel/html_head.vtl\\u0027)\\n  \\u003clink rel\\u003d\\"stylesheet\\" type\\u003d\\"text/css\\" href\\u003d\\"/html/css/template/reset-fonts-grids.css\\" /\\u003e\\n \\u003c/head\\u003e\\n \\u003cbody\\u003e\\n  \\u003cdiv id\\u003d\\"resp-template\\" name\\u003d\\"globalContainer\\"\\u003e\\n   \\u003cdiv id\\u003d\\"hd-template\\"\\u003e\\n    #dotParse(\\u0027//starter.dotcms.com/application/themes/travel/header.vtl\\u0027)\\n   \\u003c/div\\u003e\\n   \\u003cdiv id\\u003d\\"bd-template\\"\\u003e\\n    \\u003cdiv id\\u003d\\"yui-main-template\\"\\u003e\\n     \\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody0\\"\\u003e\\n      #parseContainer(\\u0027794f91e8-d7e4-43dd-a671-1157fc983821\\u0027,\\u00271564167916555\\u0027)\\n     \\u003c/div\\u003e\\n     \\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody1\\"\\u003e\\n      #parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271564167925634\\u0027)\\n     \\u003c/div\\u003e\\n    \\u003c/div\\u003e\\n   \\u003c/div\\u003e\\n   \\u003cdiv id\\u003d\\"ft-template\\"\\u003e\\n    #dotParse(\\u0027//starter.dotcms.com/application/themes/travel/footer.vtl\\u0027)\\n   \\u003c/div\\u003e\\n  \\u003c/div\\u003e\\n \\u003c/body\\u003e\\n\\u003c/html\\u003e","image":"b8e65c6b-0d8d-44d3-bafe-7f911be52db4","drawed":true,"drawedBody":"\\u003cdiv id\\u003d\\"resp-template\\" name\\u003d\\"globalContainer\\"\\u003e\\u003cdiv id\\u003d\\"hd-template\\"\\u003e\\u003ch1\\u003eHeader\\u003c/h1\\u003e\\u003c/div\\u003e\\u003cdiv id\\u003d\\"bd-template\\"\\u003e\\u003cdiv id\\u003d\\"yui-main-template\\"\\u003e\\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody0\\"\\u003e\\u003cdiv class\\u003d\\"addContainerSpan\\"\\u003e\\u003ca href\\u003d\\"javascript: showAddContainerDialog(\\u0027splitBody0\\u0027);\\" title\\u003d\\"Add Container\\"\\u003e\\u003cspan class\\u003d\\"plusBlueIcon\\"\\u003e\\u003c/span\\u003eAdd Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cspan class\\u003d\\"titleContainerSpan\\" id\\u003d\\"splitBody0_span_794f91e8-d7e4-43dd-a671-1157fc983821_1564167916555\\" title\\u003d\\"container_794f91e8-d7e4-43dd-a671-1157fc983821\\"\\u003e\\u003cdiv class\\u003d\\"removeDiv\\"\\u003e\\u003ca href\\u003d\\"javascript: removeDrawedContainer(\\u0027splitBody0\\u0027,\\u0027794f91e8-d7e4-43dd-a671-1157fc983821\\u0027,\\u00271564167916555\\u0027);\\" title\\u003d\\"Remove Container\\"\\u003e\\u003cspan class\\u003d\\"minusIcon\\"\\u003e\\u003c/span\\u003eRemove Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"clear\\"\\u003e\\u003c/div\\u003e\\u003ch2\\u003eContainer: Breadcrumbs\\u003c/h2\\u003e\\u003cp\\u003eLorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\\u003c/p\\u003e\\u003c/span\\u003e\\u003cdiv style\\u003d\\"display: none;\\" title\\u003d\\"container_794f91e8-d7e4-43dd-a671-1157fc983821\\" id\\u003d\\"splitBody0_div_794f91e8-d7e4-43dd-a671-1157fc983821_1564167916555\\"\\u003e#parseContainer(\\u0027794f91e8-d7e4-43dd-a671-1157fc983821\\u0027,\\u00271564167916555\\u0027)\\r\\n\\u003c/div\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody1\\"\\u003e\\u003cdiv class\\u003d\\"addContainerSpan\\"\\u003e\\u003ca href\\u003d\\"javascript: showAddContainerDialog(\\u0027splitBody1\\u0027);\\" title\\u003d\\"Add Container\\"\\u003e\\u003cspan class\\u003d\\"plusBlueIcon\\"\\u003e\\u003c/span\\u003eAdd Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cspan class\\u003d\\"titleContainerSpan\\" id\\u003d\\"splitBody1_span_69b3d24d-7e80-4be6-b04a-d352d16493ee_1564167925634\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\"\\u003e\\u003cdiv class\\u003d\\"removeDiv\\"\\u003e\\u003ca href\\u003d\\"javascript: removeDrawedContainer(\\u0027splitBody1\\u0027,\\u002769b3d24d-7e80-4be6-b04a-d352d16493ee\\u0027,\\u00271564167925634\\u0027);\\" title\\u003d\\"Remove Container\\"\\u003e\\u003cspan class\\u003d\\"minusIcon\\"\\u003e\\u003c/span\\u003eRemove Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"clear\\"\\u003e\\u003c/div\\u003e\\u003ch2\\u003eContainer: Default\\u003c/h2\\u003e\\u003cp\\u003eLorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\\u003c/p\\u003e\\u003c/span\\u003e\\u003cdiv style\\u003d\\"display: none;\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\" id\\u003d\\"splitBody1_div_69b3d24d-7e80-4be6-b04a-d352d16493ee_1564167925634\\"\\u003e#parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271564167925634\\u0027)\\r\\n\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003cdiv id\\u003d\\"ft-template\\"\\u003e\\u003ch1\\u003eFooter\\u003c/h1\\u003e\\u003c/div\\u003e\\u003c/div\\u003e","countAddContainer":0,"countContainers":0,"theme":"d7b0ebc2-37ca-4a5a-b769-e8a3ff187661","source":"DB","title":"Default with Breadcrumbs","friendlyName":"Default template with breadcrumbs","modDate":1585198157846,"modUser":"dotcms.org.1","sortOrder":0,"showOnMenu":true,"iDate":1567002916601,"type":"template","inode":"574d6ad5-a950-432c-997c-7c1a35eefed3","identifier":"b47f4afc-7ccc-4358-a063-97763779baac"}}	1585198157847	e64a5620-9bd4-4e08-a53a-67a80079eea1
ccaedb0d-5f5c-4bbd-9a21-6198394763f6	ARCHIVE_LINK	{"type":"com.dotmarketing.portlets.templates.model.Template","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"PERMISSION","visibilityValue":1,"visibilityType":"java.lang.Integer"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"body":"\\u003chtml\\u003e\\n \\u003chead\\u003e\\n  #dotParse(\\u0027//starter.dotcms.com/application/themes/travel/html_head.vtl\\u0027)\\n  \\u003clink rel\\u003d\\"stylesheet\\" type\\u003d\\"text/css\\" href\\u003d\\"/html/css/template/reset-fonts-grids.css\\" /\\u003e\\n \\u003c/head\\u003e\\n \\u003cbody\\u003e\\n  \\u003cdiv id\\u003d\\"resp-template\\" name\\u003d\\"globalContainer\\"\\u003e\\n   \\u003cdiv id\\u003d\\"hd-template\\"\\u003e\\n    #dotParse(\\u0027//starter.dotcms.com/application/themes/travel/header.vtl\\u0027)\\n   \\u003c/div\\u003e\\n   \\u003cdiv id\\u003d\\"bd-template\\"\\u003e\\n    \\u003cdiv id\\u003d\\"yui-main-template\\"\\u003e\\n     \\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody0\\"\\u003e\\n      #parseContainer(\\u0027794f91e8-d7e4-43dd-a671-1157fc983821\\u0027,\\u00271564167916555\\u0027)\\n     \\u003c/div\\u003e\\n     \\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody1\\"\\u003e\\n      #parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271564167925634\\u0027)\\n     \\u003c/div\\u003e\\n    \\u003c/div\\u003e\\n   \\u003c/div\\u003e\\n   \\u003cdiv id\\u003d\\"ft-template\\"\\u003e\\n    #dotParse(\\u0027//starter.dotcms.com/application/themes/travel/footer.vtl\\u0027)\\n   \\u003c/div\\u003e\\n  \\u003c/div\\u003e\\n \\u003c/body\\u003e\\n\\u003c/html\\u003e","image":"b8e65c6b-0d8d-44d3-bafe-7f911be52db4","drawed":true,"drawedBody":"\\u003cdiv id\\u003d\\"resp-template\\" name\\u003d\\"globalContainer\\"\\u003e\\u003cdiv id\\u003d\\"hd-template\\"\\u003e\\u003ch1\\u003eHeader\\u003c/h1\\u003e\\u003c/div\\u003e\\u003cdiv id\\u003d\\"bd-template\\"\\u003e\\u003cdiv id\\u003d\\"yui-main-template\\"\\u003e\\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody0\\"\\u003e\\u003cdiv class\\u003d\\"addContainerSpan\\"\\u003e\\u003ca href\\u003d\\"javascript: showAddContainerDialog(\\u0027splitBody0\\u0027);\\" title\\u003d\\"Add Container\\"\\u003e\\u003cspan class\\u003d\\"plusBlueIcon\\"\\u003e\\u003c/span\\u003eAdd Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cspan class\\u003d\\"titleContainerSpan\\" id\\u003d\\"splitBody0_span_794f91e8-d7e4-43dd-a671-1157fc983821_1564167916555\\" title\\u003d\\"container_794f91e8-d7e4-43dd-a671-1157fc983821\\"\\u003e\\u003cdiv class\\u003d\\"removeDiv\\"\\u003e\\u003ca href\\u003d\\"javascript: removeDrawedContainer(\\u0027splitBody0\\u0027,\\u0027794f91e8-d7e4-43dd-a671-1157fc983821\\u0027,\\u00271564167916555\\u0027);\\" title\\u003d\\"Remove Container\\"\\u003e\\u003cspan class\\u003d\\"minusIcon\\"\\u003e\\u003c/span\\u003eRemove Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"clear\\"\\u003e\\u003c/div\\u003e\\u003ch2\\u003eContainer: Breadcrumbs\\u003c/h2\\u003e\\u003cp\\u003eLorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\\u003c/p\\u003e\\u003c/span\\u003e\\u003cdiv style\\u003d\\"display: none;\\" title\\u003d\\"container_794f91e8-d7e4-43dd-a671-1157fc983821\\" id\\u003d\\"splitBody0_div_794f91e8-d7e4-43dd-a671-1157fc983821_1564167916555\\"\\u003e#parseContainer(\\u0027794f91e8-d7e4-43dd-a671-1157fc983821\\u0027,\\u00271564167916555\\u0027)\\r\\n\\u003c/div\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody1\\"\\u003e\\u003cdiv class\\u003d\\"addContainerSpan\\"\\u003e\\u003ca href\\u003d\\"javascript: showAddContainerDialog(\\u0027splitBody1\\u0027);\\" title\\u003d\\"Add Container\\"\\u003e\\u003cspan class\\u003d\\"plusBlueIcon\\"\\u003e\\u003c/span\\u003eAdd Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cspan class\\u003d\\"titleContainerSpan\\" id\\u003d\\"splitBody1_span_69b3d24d-7e80-4be6-b04a-d352d16493ee_1564167925634\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\"\\u003e\\u003cdiv class\\u003d\\"removeDiv\\"\\u003e\\u003ca href\\u003d\\"javascript: removeDrawedContainer(\\u0027splitBody1\\u0027,\\u002769b3d24d-7e80-4be6-b04a-d352d16493ee\\u0027,\\u00271564167925634\\u0027);\\" title\\u003d\\"Remove Container\\"\\u003e\\u003cspan class\\u003d\\"minusIcon\\"\\u003e\\u003c/span\\u003eRemove Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"clear\\"\\u003e\\u003c/div\\u003e\\u003ch2\\u003eContainer: Default\\u003c/h2\\u003e\\u003cp\\u003eLorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\\u003c/p\\u003e\\u003c/span\\u003e\\u003cdiv style\\u003d\\"display: none;\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\" id\\u003d\\"splitBody1_div_69b3d24d-7e80-4be6-b04a-d352d16493ee_1564167925634\\"\\u003e#parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271564167925634\\u0027)\\r\\n\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003cdiv id\\u003d\\"ft-template\\"\\u003e\\u003ch1\\u003eFooter\\u003c/h1\\u003e\\u003c/div\\u003e\\u003c/div\\u003e","countAddContainer":0,"countContainers":0,"theme":"d7b0ebc2-37ca-4a5a-b769-e8a3ff187661","source":"DB","title":"Default with Breadcrumbs","friendlyName":"Default template with breadcrumbs","modDate":1585198161137,"modUser":"dotcms.org.1","sortOrder":0,"showOnMenu":true,"iDate":1567002916601,"type":"template","inode":"574d6ad5-a950-432c-997c-7c1a35eefed3","identifier":"b47f4afc-7ccc-4358-a063-97763779baac"}}	1585198161139	e64a5620-9bd4-4e08-a53a-67a80079eea1
28dce17c-face-490c-900a-285c71c69aee	ARCHIVE_LINK	{"type":"com.dotmarketing.portlets.templates.model.Template","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"PERMISSION","visibilityValue":1,"visibilityType":"java.lang.Integer"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"body":"\\u003chtml\\u003e\\n \\u003chead\\u003e\\n  #dotParse(\\u0027//starter.dotcms.com/application/themes/travel/html_head.vtl\\u0027)\\n  \\u003clink rel\\u003d\\"stylesheet\\" type\\u003d\\"text/css\\" href\\u003d\\"/html/css/template/reset-fonts-grids.css\\" /\\u003e\\n \\u003c/head\\u003e\\n \\u003cbody\\u003e\\n  \\u003cdiv id\\u003d\\"resp-template\\" name\\u003d\\"globalContainer\\"\\u003e\\n   \\u003cdiv id\\u003d\\"hd-template\\"\\u003e\\n    #dotParse(\\u0027//starter.dotcms.com/application/themes/travel/header.vtl\\u0027)\\n   \\u003c/div\\u003e\\n   \\u003cdiv id\\u003d\\"bd-template\\"\\u003e\\n    \\u003cdiv id\\u003d\\"yui-main-template\\"\\u003e\\n     \\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody0\\"\\u003e\\n      #parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271562770692396\\u0027)\\n     \\u003c/div\\u003e\\n    \\u003c/div\\u003e\\n   \\u003c/div\\u003e\\n   \\u003cdiv id\\u003d\\"ft-template\\"\\u003e\\n    #dotParse(\\u0027//starter.dotcms.com/application/themes/travel/footer.vtl\\u0027)\\n   \\u003c/div\\u003e\\n  \\u003c/div\\u003e\\n \\u003c/body\\u003e\\n\\u003c/html\\u003e","image":"462ebb90-7f05-4719-8d36-677756be74e1","drawed":true,"drawedBody":"\\u003cdiv id\\u003d\\"resp-template\\" name\\u003d\\"globalContainer\\"\\u003e\\u003cdiv id\\u003d\\"hd-template\\"\\u003e\\u003ch1\\u003eHeader\\u003c/h1\\u003e\\u003c/div\\u003e\\u003cdiv id\\u003d\\"bd-template\\"\\u003e\\u003cdiv id\\u003d\\"yui-main-template\\"\\u003e\\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody0\\"\\u003e\\u003cdiv class\\u003d\\"addContainerSpan\\"\\u003e\\u003ca href\\u003d\\"javascript: showAddContainerDialog(\\u0027splitBody0\\u0027);\\" title\\u003d\\"Add Container\\"\\u003e\\u003cspan class\\u003d\\"plusBlueIcon\\"\\u003e\\u003c/span\\u003eAdd Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cspan class\\u003d\\"titleContainerSpan\\" id\\u003d\\"splitBody0_span_69b3d24d-7e80-4be6-b04a-d352d16493ee_1562770692396\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\"\\u003e\\u003cdiv class\\u003d\\"removeDiv\\"\\u003e\\u003ca href\\u003d\\"javascript: removeDrawedContainer(\\u0027splitBody0\\u0027,\\u002769b3d24d-7e80-4be6-b04a-d352d16493ee\\u0027,\\u00271562770692396\\u0027);\\" title\\u003d\\"Remove Container\\"\\u003e\\u003cspan class\\u003d\\"minusIcon\\"\\u003e\\u003c/span\\u003eRemove Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"clear\\"\\u003e\\u003c/div\\u003e\\u003ch2\\u003eContainer: Default\\u003c/h2\\u003e\\u003cp\\u003eLorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\\u003c/p\\u003e\\u003c/span\\u003e\\u003cdiv style\\u003d\\"display: none;\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\" id\\u003d\\"splitBody0_div_69b3d24d-7e80-4be6-b04a-d352d16493ee_1562770692396\\"\\u003e#parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271562770692396\\u0027)\\r\\n\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003cdiv id\\u003d\\"ft-template\\"\\u003e\\u003ch1\\u003eFooter\\u003c/h1\\u003e\\u003c/div\\u003e\\u003c/div\\u003e","countAddContainer":0,"countContainers":0,"theme":"d7b0ebc2-37ca-4a5a-b769-e8a3ff187661","source":"DB","title":"Default Template","friendlyName":"Default Single Column Template","modDate":1585198163830,"modUser":"dotcms.org.1","sortOrder":0,"showOnMenu":true,"iDate":1567021150494,"type":"template","inode":"316a7de7-7b0e-4322-b925-09f177afd0c2","identifier":"31f4c794-c769-4929-9d5d-7c383408c65c"}}	1585198163832	e64a5620-9bd4-4e08-a53a-67a80079eea1
d7f79eda-6527-46a8-8322-e311b22b5fb2	DELETE_LINK	{"type":"com.dotmarketing.portlets.templates.model.Template","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"PERMISSION","visibilityValue":1,"visibilityType":"java.lang.Integer"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"body":"\\u003chtml\\u003e\\n \\u003chead\\u003e\\n  #dotParse(\\u0027//starter.dotcms.com/application/themes/landing-page/html_head.vtl\\u0027)\\n  \\u003clink rel\\u003d\\"stylesheet\\" type\\u003d\\"text/css\\" href\\u003d\\"/html/css/template/reset-fonts-grids.css\\" /\\u003e\\n \\u003c/head\\u003e\\n \\u003cbody\\u003e\\n  \\u003cdiv id\\u003d\\"resp-template\\" name\\u003d\\"globalContainer\\"\\u003e\\n   \\u003cdiv id\\u003d\\"hd-template\\"\\u003e\\n    #dotParse(\\u0027//starter.dotcms.com/application/themes/landing-page/header.vtl\\u0027)\\n   \\u003c/div\\u003e\\n   \\u003cdiv id\\u003d\\"bd-template\\"\\u003e\\n    \\u003cdiv id\\u003d\\"yui-main-template\\"\\u003e\\n     \\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody0\\"\\u003e\\n      \\u003cdiv class\\u003d\\"yui-g-template\\" id\\u003d\\"yui-g-template\\"\\u003e\\n       \\u003cdiv class\\u003d\\"yui-u-template first\\" id\\u003d\\"0_yui-u-grid-1\\"\\u003e\\n        #parseContainer(\\u002769b3d24d-7e80-4be6-b04a-d352d16493ee\\u0027,\\u00271570474272766\\u0027)\\n       \\u003c/div\\u003e\\n       \\u003cdiv class\\u003d\\"yui-u-template\\" id\\u003d\\"0_yui-u-grid-2\\"\\u003e\\n        #parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271570474279795\\u0027)\\n       \\u003c/div\\u003e\\n      \\u003c/div\\u003e\\n     \\u003c/div\\u003e\\n     \\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody1\\"\\u003e\\n      \\u003cdiv class\\u003d\\"yui-g-template\\" id\\u003d\\"yui-g-template\\"\\u003e\\n       \\u003cdiv class\\u003d\\"yui-u-template first\\" id\\u003d\\"1_yui-u-grid-1\\"\\u003e\\n        #parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271569962310124\\u0027)\\n       \\u003c/div\\u003e\\n       \\u003cdiv class\\u003d\\"yui-u-template\\" id\\u003d\\"1_yui-u-grid-2\\"\\u003e\\n        #parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271569962338553\\u0027)\\n       \\u003c/div\\u003e\\n      \\u003c/div\\u003e\\n     \\u003c/div\\u003e\\n     \\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody2\\"\\u003e\\n      \\u003cdiv class\\u003d\\"yui-g-template\\" id\\u003d\\"yui-js-template\\"\\u003e\\n       \\u003cdiv class\\u003d\\"yui-g-template\\" id\\u003d\\"yui-g-template\\"\\u003e\\n        \\u003cdiv class\\u003d\\"yui-u-template first\\" id\\u003d\\"2_yui-u-grid-1\\"\\u003e\\n         #parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271569962351862\\u0027)\\n        \\u003c/div\\u003e\\n        \\u003cdiv class\\u003d\\"yui-u-template\\" id\\u003d\\"2_yui-u-grid-2\\"\\u003e\\n         #parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271569962355912\\u0027)\\n        \\u003c/div\\u003e\\n       \\u003c/div\\u003e\\n       \\u003cdiv class\\u003d\\"yui-g-template\\" id\\u003d\\"yui-g-template\\" style\\u003d\\"margin-left:10px\\"\\u003e\\n        \\u003cdiv class\\u003d\\"yui-u-template first\\" id\\u003d\\"2_yui-u-grid-3\\"\\u003e\\n         #parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271569962359713\\u0027)\\n        \\u003c/div\\u003e\\n        \\u003cdiv class\\u003d\\"yui-u-template\\" id\\u003d\\"2_yui-u-grid-4\\"\\u003e\\n         #parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271569962363832\\u0027)\\n        \\u003c/div\\u003e\\n       \\u003c/div\\u003e\\n      \\u003c/div\\u003e\\n     \\u003c/div\\u003e\\n     \\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody3\\"\\u003e\\n      #parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271569962376026\\u0027)\\n     \\u003c/div\\u003e\\n    \\u003c/div\\u003e\\n   \\u003c/div\\u003e\\n   \\u003cdiv id\\u003d\\"ft-template\\"\\u003e\\n    #dotParse(\\u0027//starter.dotcms.com/application/themes/landing-page/footer.vtl\\u0027)\\n   \\u003c/div\\u003e\\n  \\u003c/div\\u003e\\n \\u003c/body\\u003e\\n\\u003c/html\\u003e","image":"cf7968a1-59be-4ca3-a744-5401d6c68c53","drawed":true,"drawedBody":"\\u003cdiv id\\u003d\\"resp-template\\" name\\u003d\\"globalContainer\\"\\u003e\\u003cdiv id\\u003d\\"hd-template\\"\\u003e\\u003ch1\\u003eHeader\\u003c/h1\\u003e\\u003c/div\\u003e\\u003cdiv id\\u003d\\"bd-template\\"\\u003e\\u003cdiv id\\u003d\\"yui-main-template\\"\\u003e\\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody0\\"\\u003e\\u003cdiv class\\u003d\\"yui-g-template\\" id\\u003d\\"yui-g-template\\"\\u003e\\u003cdiv class\\u003d\\"yui-u-template first\\" id\\u003d\\"0_yui-u-grid-1\\"\\u003e\\u003cdiv class\\u003d\\"addContainerSpan\\"\\u003e\\u003ca href\\u003d\\"javascript: showAddContainerDialog(\\u00270_yui-u-grid-1\\u0027);\\" title\\u003d\\"Add Container\\"\\u003e\\u003cspan class\\u003d\\"plusBlueIcon\\"\\u003e\\u003c/span\\u003eAdd Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cspan class\\u003d\\"titleContainerSpan\\" id\\u003d\\"0_yui-u-grid-1_span_69b3d24d-7e80-4be6-b04a-d352d16493ee_1570474272766\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\"\\u003e\\u003cdiv class\\u003d\\"removeDiv\\"\\u003e\\u003ca href\\u003d\\"javascript: removeDrawedContainer(\\u00270_yui-u-grid-1\\u0027,\\u002769b3d24d-7e80-4be6-b04a-d352d16493ee\\u0027,\\u00271570474272766\\u0027);\\" title\\u003d\\"Remove Container\\"\\u003e\\u003cspan class\\u003d\\"minusIcon\\"\\u003e\\u003c/span\\u003eRemove Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"clear\\"\\u003e\\u003c/div\\u003e\\u003ch2\\u003eContainer: Default\\u003c/h2\\u003e\\u003cp\\u003eLorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\\u003c/p\\u003e\\u003c/span\\u003e\\u003cdiv style\\u003d\\"display: none;\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\" id\\u003d\\"0_yui-u-grid-1_div_69b3d24d-7e80-4be6-b04a-d352d16493ee_1570474272766\\"\\u003e#parseContainer(\\u002769b3d24d-7e80-4be6-b04a-d352d16493ee\\u0027,\\u00271570474272766\\u0027)\\r\\n\\u003c/div\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"yui-u-template\\" id\\u003d\\"0_yui-u-grid-2\\"\\u003e\\u003cdiv class\\u003d\\"addContainerSpan\\"\\u003e\\u003ca href\\u003d\\"javascript: showAddContainerDialog(\\u00270_yui-u-grid-2\\u0027);\\" title\\u003d\\"Add Container\\"\\u003e\\u003cspan class\\u003d\\"plusBlueIcon\\"\\u003e\\u003c/span\\u003eAdd Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cspan class\\u003d\\"titleContainerSpan\\" id\\u003d\\"0_yui-u-grid-2_span_69b3d24d-7e80-4be6-b04a-d352d16493ee_1570474279795\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\"\\u003e\\u003cdiv class\\u003d\\"removeDiv\\"\\u003e\\u003ca href\\u003d\\"javascript: removeDrawedContainer(\\u00270_yui-u-grid-2\\u0027,\\u002769b3d24d-7e80-4be6-b04a-d352d16493ee\\u0027,\\u00271570474279795\\u0027);\\" title\\u003d\\"Remove Container\\"\\u003e\\u003cspan class\\u003d\\"minusIcon\\"\\u003e\\u003c/span\\u003eRemove Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"clear\\"\\u003e\\u003c/div\\u003e\\u003ch2\\u003eContainer: Default\\u003c/h2\\u003e\\u003cp\\u003eLorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\\u003c/p\\u003e\\u003c/span\\u003e\\u003cdiv style\\u003d\\"display: none;\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\" id\\u003d\\"0_yui-u-grid-2_div_69b3d24d-7e80-4be6-b04a-d352d16493ee_1570474279795\\"\\u003e#parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271570474279795\\u0027)\\r\\n\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody1\\"\\u003e\\u003cdiv class\\u003d\\"yui-g-template\\" id\\u003d\\"yui-g-template\\"\\u003e\\u003cdiv class\\u003d\\"yui-u-template first\\" id\\u003d\\"1_yui-u-grid-1\\"\\u003e\\u003cdiv class\\u003d\\"addContainerSpan\\"\\u003e\\u003ca href\\u003d\\"javascript: showAddContainerDialog(\\u00271_yui-u-grid-1\\u0027);\\" title\\u003d\\"Add Container\\"\\u003e\\u003cspan class\\u003d\\"plusBlueIcon\\"\\u003e\\u003c/span\\u003eAdd Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cspan class\\u003d\\"titleContainerSpan\\" id\\u003d\\"1_yui-u-grid-1_span_69b3d24d-7e80-4be6-b04a-d352d16493ee_1569962310124\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\"\\u003e\\u003cdiv class\\u003d\\"removeDiv\\"\\u003e\\u003ca href\\u003d\\"javascript: removeDrawedContainer(\\u00271_yui-u-grid-1\\u0027,\\u002769b3d24d-7e80-4be6-b04a-d352d16493ee\\u0027,\\u00271569962310124\\u0027);\\" title\\u003d\\"Remove Container\\"\\u003e\\u003cspan class\\u003d\\"minusIcon\\"\\u003e\\u003c/span\\u003eRemove Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"clear\\"\\u003e\\u003c/div\\u003e\\u003ch2\\u003eContainer: Default\\u003c/h2\\u003e\\u003cp\\u003eLorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\\u003c/p\\u003e\\u003c/span\\u003e\\u003cdiv style\\u003d\\"display: none;\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\" id\\u003d\\"1_yui-u-grid-1_div_69b3d24d-7e80-4be6-b04a-d352d16493ee_1569962310124\\"\\u003e#parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271569962310124\\u0027)\\r\\n\\u003c/div\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"yui-u-template\\" id\\u003d\\"1_yui-u-grid-2\\"\\u003e\\u003cdiv class\\u003d\\"addContainerSpan\\"\\u003e\\u003ca href\\u003d\\"javascript: showAddContainerDialog(\\u00271_yui-u-grid-2\\u0027);\\" title\\u003d\\"Add Container\\"\\u003e\\u003cspan class\\u003d\\"plusBlueIcon\\"\\u003e\\u003c/span\\u003eAdd Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cspan class\\u003d\\"titleContainerSpan\\" id\\u003d\\"1_yui-u-grid-2_span_69b3d24d-7e80-4be6-b04a-d352d16493ee_1569962338553\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\"\\u003e\\u003cdiv class\\u003d\\"removeDiv\\"\\u003e\\u003ca href\\u003d\\"javascript: removeDrawedContainer(\\u00271_yui-u-grid-2\\u0027,\\u002769b3d24d-7e80-4be6-b04a-d352d16493ee\\u0027,\\u00271569962338553\\u0027);\\" title\\u003d\\"Remove Container\\"\\u003e\\u003cspan class\\u003d\\"minusIcon\\"\\u003e\\u003c/span\\u003eRemove Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"clear\\"\\u003e\\u003c/div\\u003e\\u003ch2\\u003eContainer: Default\\u003c/h2\\u003e\\u003cp\\u003eLorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\\u003c/p\\u003e\\u003c/span\\u003e\\u003cdiv style\\u003d\\"display: none;\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\" id\\u003d\\"1_yui-u-grid-2_div_69b3d24d-7e80-4be6-b04a-d352d16493ee_1569962338553\\"\\u003e#parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271569962338553\\u0027)\\r\\n\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody2\\"\\u003e\\u003cdiv class\\u003d\\"yui-g-template\\" id\\u003d\\"yui-js-template\\"\\u003e\\u003cdiv class\\u003d\\"yui-g-template\\" id\\u003d\\"yui-g-template\\"\\u003e\\u003cdiv class\\u003d\\"yui-u-template first\\" id\\u003d\\"2_yui-u-grid-1\\"\\u003e\\u003cdiv class\\u003d\\"addContainerSpan\\"\\u003e\\u003ca href\\u003d\\"javascript: showAddContainerDialog(\\u00272_yui-u-grid-1\\u0027);\\" title\\u003d\\"Add Container\\"\\u003e\\u003cspan class\\u003d\\"plusBlueIcon\\"\\u003e\\u003c/span\\u003eAdd Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cspan class\\u003d\\"titleContainerSpan\\" id\\u003d\\"2_yui-u-grid-1_span_69b3d24d-7e80-4be6-b04a-d352d16493ee_1569962351862\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\"\\u003e\\u003cdiv class\\u003d\\"removeDiv\\"\\u003e\\u003ca href\\u003d\\"javascript: removeDrawedContainer(\\u00272_yui-u-grid-1\\u0027,\\u002769b3d24d-7e80-4be6-b04a-d352d16493ee\\u0027,\\u00271569962351862\\u0027);\\" title\\u003d\\"Remove Container\\"\\u003e\\u003cspan class\\u003d\\"minusIcon\\"\\u003e\\u003c/span\\u003eRemove Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"clear\\"\\u003e\\u003c/div\\u003e\\u003ch2\\u003eContainer: Default\\u003c/h2\\u003e\\u003cp\\u003eLorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\\u003c/p\\u003e\\u003c/span\\u003e\\u003cdiv style\\u003d\\"display: none;\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\" id\\u003d\\"2_yui-u-grid-1_div_69b3d24d-7e80-4be6-b04a-d352d16493ee_1569962351862\\"\\u003e#parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271569962351862\\u0027)\\r\\n\\u003c/div\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"yui-u-template\\" id\\u003d\\"2_yui-u-grid-2\\"\\u003e\\u003cdiv class\\u003d\\"addContainerSpan\\"\\u003e\\u003ca href\\u003d\\"javascript: showAddContainerDialog(\\u00272_yui-u-grid-2\\u0027);\\" title\\u003d\\"Add Container\\"\\u003e\\u003cspan class\\u003d\\"plusBlueIcon\\"\\u003e\\u003c/span\\u003eAdd Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cspan class\\u003d\\"titleContainerSpan\\" id\\u003d\\"2_yui-u-grid-2_span_69b3d24d-7e80-4be6-b04a-d352d16493ee_1569962355912\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\"\\u003e\\u003cdiv class\\u003d\\"removeDiv\\"\\u003e\\u003ca href\\u003d\\"javascript: removeDrawedContainer(\\u00272_yui-u-grid-2\\u0027,\\u002769b3d24d-7e80-4be6-b04a-d352d16493ee\\u0027,\\u00271569962355912\\u0027);\\" title\\u003d\\"Remove Container\\"\\u003e\\u003cspan class\\u003d\\"minusIcon\\"\\u003e\\u003c/span\\u003eRemove Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"clear\\"\\u003e\\u003c/div\\u003e\\u003ch2\\u003eContainer: Default\\u003c/h2\\u003e\\u003cp\\u003eLorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\\u003c/p\\u003e\\u003c/span\\u003e\\u003cdiv style\\u003d\\"display: none;\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\" id\\u003d\\"2_yui-u-grid-2_div_69b3d24d-7e80-4be6-b04a-d352d16493ee_1569962355912\\"\\u003e#parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271569962355912\\u0027)\\r\\n\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"yui-g-template\\" id\\u003d\\"yui-g-template\\" style\\u003d\\"margin-left:10px\\"\\u003e\\u003cdiv class\\u003d\\"yui-u-template first\\" id\\u003d\\"2_yui-u-grid-3\\"\\u003e\\u003cdiv class\\u003d\\"addContainerSpan\\"\\u003e\\u003ca href\\u003d\\"javascript: showAddContainerDialog(\\u00272_yui-u-grid-3\\u0027);\\" title\\u003d\\"Add Container\\"\\u003e\\u003cspan class\\u003d\\"plusBlueIcon\\"\\u003e\\u003c/span\\u003eAdd Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cspan class\\u003d\\"titleContainerSpan\\" id\\u003d\\"2_yui-u-grid-3_span_69b3d24d-7e80-4be6-b04a-d352d16493ee_1569962359713\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\"\\u003e\\u003cdiv class\\u003d\\"removeDiv\\"\\u003e\\u003ca href\\u003d\\"javascript: removeDrawedContainer(\\u00272_yui-u-grid-3\\u0027,\\u002769b3d24d-7e80-4be6-b04a-d352d16493ee\\u0027,\\u00271569962359713\\u0027);\\" title\\u003d\\"Remove Container\\"\\u003e\\u003cspan class\\u003d\\"minusIcon\\"\\u003e\\u003c/span\\u003eRemove Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"clear\\"\\u003e\\u003c/div\\u003e\\u003ch2\\u003eContainer: Default\\u003c/h2\\u003e\\u003cp\\u003eLorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\\u003c/p\\u003e\\u003c/span\\u003e\\u003cdiv style\\u003d\\"display: none;\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\" id\\u003d\\"2_yui-u-grid-3_div_69b3d24d-7e80-4be6-b04a-d352d16493ee_1569962359713\\"\\u003e#parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271569962359713\\u0027)\\r\\n\\u003c/div\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"yui-u-template\\" id\\u003d\\"2_yui-u-grid-4\\"\\u003e\\u003cdiv class\\u003d\\"addContainerSpan\\"\\u003e\\u003ca href\\u003d\\"javascript: showAddContainerDialog(\\u00272_yui-u-grid-4\\u0027);\\" title\\u003d\\"Add Container\\"\\u003e\\u003cspan class\\u003d\\"plusBlueIcon\\"\\u003e\\u003c/span\\u003eAdd Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cspan class\\u003d\\"titleContainerSpan\\" id\\u003d\\"2_yui-u-grid-4_span_69b3d24d-7e80-4be6-b04a-d352d16493ee_1569962363832\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\"\\u003e\\u003cdiv class\\u003d\\"removeDiv\\"\\u003e\\u003ca href\\u003d\\"javascript: removeDrawedContainer(\\u00272_yui-u-grid-4\\u0027,\\u002769b3d24d-7e80-4be6-b04a-d352d16493ee\\u0027,\\u00271569962363832\\u0027);\\" title\\u003d\\"Remove Container\\"\\u003e\\u003cspan class\\u003d\\"minusIcon\\"\\u003e\\u003c/span\\u003eRemove Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"clear\\"\\u003e\\u003c/div\\u003e\\u003ch2\\u003eContainer: Default\\u003c/h2\\u003e\\u003cp\\u003eLorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\\u003c/p\\u003e\\u003c/span\\u003e\\u003cdiv style\\u003d\\"display: none;\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\" id\\u003d\\"2_yui-u-grid-4_div_69b3d24d-7e80-4be6-b04a-d352d16493ee_1569962363832\\"\\u003e#parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271569962363832\\u0027)\\r\\n\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody3\\"\\u003e\\u003cdiv class\\u003d\\"addContainerSpan\\"\\u003e\\u003ca href\\u003d\\"javascript: showAddContainerDialog(\\u0027splitBody3\\u0027);\\" title\\u003d\\"Add Container\\"\\u003e\\u003cspan class\\u003d\\"plusBlueIcon\\"\\u003e\\u003c/span\\u003eAdd Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cspan class\\u003d\\"titleContainerSpan\\" id\\u003d\\"splitBody3_span_69b3d24d-7e80-4be6-b04a-d352d16493ee_1569962376026\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\"\\u003e\\u003cdiv class\\u003d\\"removeDiv\\"\\u003e\\u003ca href\\u003d\\"javascript: removeDrawedContainer(\\u0027splitBody3\\u0027,\\u002769b3d24d-7e80-4be6-b04a-d352d16493ee\\u0027,\\u00271569962376026\\u0027);\\" title\\u003d\\"Remove Container\\"\\u003e\\u003cspan class\\u003d\\"minusIcon\\"\\u003e\\u003c/span\\u003eRemove Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"clear\\"\\u003e\\u003c/div\\u003e\\u003ch2\\u003eContainer: Default\\u003c/h2\\u003e\\u003cp\\u003eLorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\\u003c/p\\u003e\\u003c/span\\u003e\\u003cdiv style\\u003d\\"display: none;\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\" id\\u003d\\"splitBody3_div_69b3d24d-7e80-4be6-b04a-d352d16493ee_1569962376026\\"\\u003e#parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271569962376026\\u0027)\\r\\n\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003cdiv id\\u003d\\"ft-template\\"\\u003e\\u003ch1\\u003eFooter\\u003c/h1\\u003e\\u003c/div\\u003e\\u003c/div\\u003e","countAddContainer":0,"countContainers":0,"theme":"ce00bd28-5f66-47f9-96ca-bbf0722a79aa","source":"DB","title":"Landing Page","friendlyName":"Marketing Landing Page","modDate":1585198172420,"modUser":"dotcms.org.1","sortOrder":0,"showOnMenu":true,"iDate":1571781566313,"type":"template","inode":"3a79250a-cd9c-455f-b41c-64a18088cd93","identifier":"fde4c167-edf4-4699-8a3a-0bf155067555"}}	1585198178459	e64a5620-9bd4-4e08-a53a-67a80079eea1
85f812e4-b3e0-4dbc-9de9-8ed122f17c42	DELETE_LINK	{"type":"com.dotmarketing.portlets.templates.model.Template","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"PERMISSION","visibilityValue":1,"visibilityType":"java.lang.Integer"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"body":"\\u003chtml\\u003e\\n \\u003chead\\u003e\\n  #dotParse(\\u0027//starter.dotcms.com/application/themes/travel/html_head.vtl\\u0027)\\n  \\u003clink rel\\u003d\\"stylesheet\\" type\\u003d\\"text/css\\" href\\u003d\\"/html/css/template/reset-fonts-grids.css\\" /\\u003e\\n \\u003c/head\\u003e\\n \\u003cbody\\u003e\\n  \\u003cdiv id\\u003d\\"resp-template\\" name\\u003d\\"globalContainer\\"\\u003e\\n   \\u003cdiv id\\u003d\\"hd-template\\"\\u003e\\n    #dotParse(\\u0027//starter.dotcms.com/application/themes/travel/header.vtl\\u0027)\\n   \\u003c/div\\u003e\\n   \\u003cdiv id\\u003d\\"bd-template\\"\\u003e\\n    \\u003cdiv id\\u003d\\"yui-main-template\\"\\u003e\\n     \\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody0\\"\\u003e\\n      #parseContainer(\\u00275a07f889-4536-4956-aa6e-e7967969ec3f\\u0027,\\u00271567007125001\\u0027)\\n     \\u003c/div\\u003e\\n     \\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody1\\"\\u003e\\n      \\u003cdiv class\\u003d\\"yui-g-template\\" id\\u003d\\"yui-g-template\\"\\u003e\\n       \\u003cdiv class\\u003d\\"yui-u-template first\\" id\\u003d\\"1_yui-u-grid-1\\"\\u003e\\n        #parseContainer(\\u002769b3d24d-7e80-4be6-b04a-d352d16493ee\\u0027,\\u00271567007147855\\u0027)\\n       \\u003c/div\\u003e\\n       \\u003cdiv class\\u003d\\"yui-u-template\\" id\\u003d\\"1_yui-u-grid-2\\"\\u003e\\n        #parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271567007153936\\u0027)\\n       \\u003c/div\\u003e\\n      \\u003c/div\\u003e\\n     \\u003c/div\\u003e\\n     \\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody3\\"\\u003e\\n      #parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271567007193334\\u0027)\\n     \\u003c/div\\u003e\\n    \\u003c/div\\u003e\\n   \\u003c/div\\u003e\\n   \\u003cdiv id\\u003d\\"ft-template\\"\\u003e\\n    #dotParse(\\u0027//starter.dotcms.com/application/themes/travel/footer.vtl\\u0027)\\n   \\u003c/div\\u003e\\n  \\u003c/div\\u003e\\n \\u003c/body\\u003e\\n\\u003c/html\\u003e","image":"","drawed":true,"drawedBody":"\\u003cdiv id\\u003d\\"resp-template\\" name\\u003d\\"globalContainer\\"\\u003e\\u003cdiv id\\u003d\\"hd-template\\"\\u003e\\u003ch1\\u003eHeader\\u003c/h1\\u003e\\u003c/div\\u003e\\u003cdiv id\\u003d\\"bd-template\\"\\u003e\\u003cdiv id\\u003d\\"yui-main-template\\"\\u003e\\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody0\\"\\u003e\\u003cdiv class\\u003d\\"addContainerSpan\\"\\u003e\\u003ca href\\u003d\\"javascript: showAddContainerDialog(\\u0027splitBody0\\u0027);\\" title\\u003d\\"Add Container\\"\\u003e\\u003cspan class\\u003d\\"plusBlueIcon\\"\\u003e\\u003c/span\\u003eAdd Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cspan class\\u003d\\"titleContainerSpan\\" id\\u003d\\"splitBody0_span_5a07f889-4536-4956-aa6e-e7967969ec3f_1567007125001\\" title\\u003d\\"container_5a07f889-4536-4956-aa6e-e7967969ec3f\\"\\u003e\\u003cdiv class\\u003d\\"removeDiv\\"\\u003e\\u003ca href\\u003d\\"javascript: removeDrawedContainer(\\u0027splitBody0\\u0027,\\u00275a07f889-4536-4956-aa6e-e7967969ec3f\\u0027,\\u00271567007125001\\u0027);\\" title\\u003d\\"Remove Container\\"\\u003e\\u003cspan class\\u003d\\"minusIcon\\"\\u003e\\u003c/span\\u003eRemove Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"clear\\"\\u003e\\u003c/div\\u003e\\u003ch2\\u003eContainer: Banner\\u003c/h2\\u003e\\u003cp\\u003eLorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\\u003c/p\\u003e\\u003c/span\\u003e\\u003cdiv style\\u003d\\"display: none;\\" title\\u003d\\"container_5a07f889-4536-4956-aa6e-e7967969ec3f\\" id\\u003d\\"splitBody0_div_5a07f889-4536-4956-aa6e-e7967969ec3f_1567007125001\\"\\u003e#parseContainer(\\u00275a07f889-4536-4956-aa6e-e7967969ec3f\\u0027,\\u00271567007125001\\u0027)\\r\\n\\u003c/div\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody1\\"\\u003e\\u003cdiv class\\u003d\\"yui-g-template\\" id\\u003d\\"yui-g-template\\"\\u003e\\u003cdiv class\\u003d\\"yui-u-template first\\" id\\u003d\\"1_yui-u-grid-1\\"\\u003e\\u003cdiv class\\u003d\\"addContainerSpan\\"\\u003e\\u003ca href\\u003d\\"javascript: showAddContainerDialog(\\u00271_yui-u-grid-1\\u0027);\\" title\\u003d\\"Add Container\\"\\u003e\\u003cspan class\\u003d\\"plusBlueIcon\\"\\u003e\\u003c/span\\u003eAdd Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cspan class\\u003d\\"titleContainerSpan\\" id\\u003d\\"1_yui-u-grid-1_span_69b3d24d-7e80-4be6-b04a-d352d16493ee_1567007147855\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\"\\u003e\\u003cdiv class\\u003d\\"removeDiv\\"\\u003e\\u003ca href\\u003d\\"javascript: removeDrawedContainer(\\u00271_yui-u-grid-1\\u0027,\\u002769b3d24d-7e80-4be6-b04a-d352d16493ee\\u0027,\\u00271567007147855\\u0027);\\" title\\u003d\\"Remove Container\\"\\u003e\\u003cspan class\\u003d\\"minusIcon\\"\\u003e\\u003c/span\\u003eRemove Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"clear\\"\\u003e\\u003c/div\\u003e\\u003ch2\\u003eContainer: Default\\u003c/h2\\u003e\\u003cp\\u003eLorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\\u003c/p\\u003e\\u003c/span\\u003e\\u003cdiv style\\u003d\\"display: none;\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\" id\\u003d\\"1_yui-u-grid-1_div_69b3d24d-7e80-4be6-b04a-d352d16493ee_1567007147855\\"\\u003e#parseContainer(\\u002769b3d24d-7e80-4be6-b04a-d352d16493ee\\u0027,\\u00271567007147855\\u0027)\\r\\n\\u003c/div\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"yui-u-template\\" id\\u003d\\"1_yui-u-grid-2\\"\\u003e\\u003cdiv class\\u003d\\"addContainerSpan\\"\\u003e\\u003ca href\\u003d\\"javascript: showAddContainerDialog(\\u00271_yui-u-grid-2\\u0027);\\" title\\u003d\\"Add Container\\"\\u003e\\u003cspan class\\u003d\\"plusBlueIcon\\"\\u003e\\u003c/span\\u003eAdd Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cspan class\\u003d\\"titleContainerSpan\\" id\\u003d\\"1_yui-u-grid-2_span_69b3d24d-7e80-4be6-b04a-d352d16493ee_1567007153936\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\"\\u003e\\u003cdiv class\\u003d\\"removeDiv\\"\\u003e\\u003ca href\\u003d\\"javascript: removeDrawedContainer(\\u00271_yui-u-grid-2\\u0027,\\u002769b3d24d-7e80-4be6-b04a-d352d16493ee\\u0027,\\u00271567007153936\\u0027);\\" title\\u003d\\"Remove Container\\"\\u003e\\u003cspan class\\u003d\\"minusIcon\\"\\u003e\\u003c/span\\u003eRemove Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"clear\\"\\u003e\\u003c/div\\u003e\\u003ch2\\u003eContainer: Default\\u003c/h2\\u003e\\u003cp\\u003eLorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\\u003c/p\\u003e\\u003c/span\\u003e\\u003cdiv style\\u003d\\"display: none;\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\" id\\u003d\\"1_yui-u-grid-2_div_69b3d24d-7e80-4be6-b04a-d352d16493ee_1567007153936\\"\\u003e#parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271567007153936\\u0027)\\r\\n\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody3\\"\\u003e\\u003cdiv class\\u003d\\"addContainerSpan\\"\\u003e\\u003ca href\\u003d\\"javascript: showAddContainerDialog(\\u0027splitBody3\\u0027);\\" title\\u003d\\"Add Container\\"\\u003e\\u003cspan class\\u003d\\"plusBlueIcon\\"\\u003e\\u003c/span\\u003eAdd Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cspan class\\u003d\\"titleContainerSpan\\" id\\u003d\\"splitBody3_span_69b3d24d-7e80-4be6-b04a-d352d16493ee_1567007193334\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\"\\u003e\\u003cdiv class\\u003d\\"removeDiv\\"\\u003e\\u003ca href\\u003d\\"javascript: removeDrawedContainer(\\u0027splitBody3\\u0027,\\u002769b3d24d-7e80-4be6-b04a-d352d16493ee\\u0027,\\u00271567007193334\\u0027);\\" title\\u003d\\"Remove Container\\"\\u003e\\u003cspan class\\u003d\\"minusIcon\\"\\u003e\\u003c/span\\u003eRemove Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"clear\\"\\u003e\\u003c/div\\u003e\\u003ch2\\u003eContainer: Default\\u003c/h2\\u003e\\u003cp\\u003eLorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\\u003c/p\\u003e\\u003c/span\\u003e\\u003cdiv style\\u003d\\"display: none;\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\" id\\u003d\\"splitBody3_div_69b3d24d-7e80-4be6-b04a-d352d16493ee_1567007193334\\"\\u003e#parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271567007193334\\u0027)\\r\\n\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003cdiv id\\u003d\\"ft-template\\"\\u003e\\u003ch1\\u003eFooter\\u003c/h1\\u003e\\u003c/div\\u003e\\u003c/div\\u003e","countAddContainer":0,"countContainers":0,"theme":"d7b0ebc2-37ca-4a5a-b769-e8a3ff187661","source":"DB","title":"Destination","friendlyName":"Resort Destination Landing Page","modDate":1585198169953,"modUser":"dotcms.org.1","sortOrder":0,"showOnMenu":true,"iDate":1571781392715,"type":"template","inode":"75bfe924-3a59-4cff-aa59-2b9b00a20efe","identifier":"c634d093-c97d-4c37-9004-1262b4578c3e"}}	1585198181052	e64a5620-9bd4-4e08-a53a-67a80079eea1
4d64d776-1673-472a-9f16-4d9e2527ffa0	DELETE_LINK	{"type":"com.dotmarketing.portlets.templates.model.Template","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"PERMISSION","visibilityValue":1,"visibilityType":"java.lang.Integer"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"body":"## Container: Blank Container\\r\\n## This is autogenerated code that cannot be changed\\r\\n#parseContainer(\\u0027d71d56b4-0a8b-4bb2-be15-ffa5a23366ea\\u0027,\\u00271539784124854\\u0027)\\r\\n","image":"21ea6da6-68d0-48db-bce8-d1691abd6314","drawed":false,"countAddContainer":0,"countContainers":0,"source":"DB","title":"Blank","friendlyName":"Blank template (No: header, footer, javascript or css)","modDate":1585198167304,"modUser":"dotcms.org.1","sortOrder":0,"showOnMenu":true,"iDate":1570214794641,"type":"template","inode":"9d11b327-9bf5-4d42-92bd-7894d56ed218","identifier":"7acdb856-4bbc-41c5-8695-a39c2e4a913f"}}	1585198183274	e64a5620-9bd4-4e08-a53a-67a80079eea1
608db6d6-20f2-437b-98ec-a51af55c688a	DELETE_LINK	{"type":"com.dotmarketing.portlets.templates.model.Template","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"PERMISSION","visibilityValue":1,"visibilityType":"java.lang.Integer"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"body":"\\u003chtml\\u003e\\n \\u003chead\\u003e\\n  #dotParse(\\u0027//starter.dotcms.com/application/themes/travel/html_head.vtl\\u0027)\\n  \\u003clink rel\\u003d\\"stylesheet\\" type\\u003d\\"text/css\\" href\\u003d\\"/html/css/template/reset-fonts-grids.css\\" /\\u003e\\n \\u003c/head\\u003e\\n \\u003cbody\\u003e\\n  \\u003cdiv id\\u003d\\"resp-template\\" name\\u003d\\"globalContainer\\"\\u003e\\n   \\u003cdiv id\\u003d\\"hd-template\\"\\u003e\\n    #dotParse(\\u0027//starter.dotcms.com/application/themes/travel/header.vtl\\u0027)\\n   \\u003c/div\\u003e\\n   \\u003cdiv id\\u003d\\"bd-template\\"\\u003e\\n    \\u003cdiv id\\u003d\\"yui-main-template\\"\\u003e\\n     \\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody0\\"\\u003e\\n      #parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271562770692396\\u0027)\\n     \\u003c/div\\u003e\\n    \\u003c/div\\u003e\\n   \\u003c/div\\u003e\\n   \\u003cdiv id\\u003d\\"ft-template\\"\\u003e\\n    #dotParse(\\u0027//starter.dotcms.com/application/themes/travel/footer.vtl\\u0027)\\n   \\u003c/div\\u003e\\n  \\u003c/div\\u003e\\n \\u003c/body\\u003e\\n\\u003c/html\\u003e","image":"462ebb90-7f05-4719-8d36-677756be74e1","drawed":true,"drawedBody":"\\u003cdiv id\\u003d\\"resp-template\\" name\\u003d\\"globalContainer\\"\\u003e\\u003cdiv id\\u003d\\"hd-template\\"\\u003e\\u003ch1\\u003eHeader\\u003c/h1\\u003e\\u003c/div\\u003e\\u003cdiv id\\u003d\\"bd-template\\"\\u003e\\u003cdiv id\\u003d\\"yui-main-template\\"\\u003e\\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody0\\"\\u003e\\u003cdiv class\\u003d\\"addContainerSpan\\"\\u003e\\u003ca href\\u003d\\"javascript: showAddContainerDialog(\\u0027splitBody0\\u0027);\\" title\\u003d\\"Add Container\\"\\u003e\\u003cspan class\\u003d\\"plusBlueIcon\\"\\u003e\\u003c/span\\u003eAdd Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cspan class\\u003d\\"titleContainerSpan\\" id\\u003d\\"splitBody0_span_69b3d24d-7e80-4be6-b04a-d352d16493ee_1562770692396\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\"\\u003e\\u003cdiv class\\u003d\\"removeDiv\\"\\u003e\\u003ca href\\u003d\\"javascript: removeDrawedContainer(\\u0027splitBody0\\u0027,\\u002769b3d24d-7e80-4be6-b04a-d352d16493ee\\u0027,\\u00271562770692396\\u0027);\\" title\\u003d\\"Remove Container\\"\\u003e\\u003cspan class\\u003d\\"minusIcon\\"\\u003e\\u003c/span\\u003eRemove Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"clear\\"\\u003e\\u003c/div\\u003e\\u003ch2\\u003eContainer: Default\\u003c/h2\\u003e\\u003cp\\u003eLorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\\u003c/p\\u003e\\u003c/span\\u003e\\u003cdiv style\\u003d\\"display: none;\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\" id\\u003d\\"splitBody0_div_69b3d24d-7e80-4be6-b04a-d352d16493ee_1562770692396\\"\\u003e#parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271562770692396\\u0027)\\r\\n\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003cdiv id\\u003d\\"ft-template\\"\\u003e\\u003ch1\\u003eFooter\\u003c/h1\\u003e\\u003c/div\\u003e\\u003c/div\\u003e","countAddContainer":0,"countContainers":0,"theme":"d7b0ebc2-37ca-4a5a-b769-e8a3ff187661","source":"DB","title":"Default Template","friendlyName":"Default Single Column Template","modDate":1585198163830,"modUser":"dotcms.org.1","sortOrder":0,"showOnMenu":true,"iDate":1567021150494,"type":"template","inode":"316a7de7-7b0e-4322-b925-09f177afd0c2","identifier":"31f4c794-c769-4929-9d5d-7c383408c65c"}}	1585198185703	e64a5620-9bd4-4e08-a53a-67a80079eea1
d69a7a97-bf46-4776-921c-011c17e046b4	DELETE_LINK	{"type":"com.dotmarketing.portlets.templates.model.Template","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"PERMISSION","visibilityValue":1,"visibilityType":"java.lang.Integer"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"body":"\\u003chtml\\u003e\\n \\u003chead\\u003e\\n  #dotParse(\\u0027//starter.dotcms.com/application/themes/travel/html_head.vtl\\u0027)\\n  \\u003clink rel\\u003d\\"stylesheet\\" type\\u003d\\"text/css\\" href\\u003d\\"/html/css/template/reset-fonts-grids.css\\" /\\u003e\\n \\u003c/head\\u003e\\n \\u003cbody\\u003e\\n  \\u003cdiv id\\u003d\\"resp-template\\" name\\u003d\\"globalContainer\\"\\u003e\\n   \\u003cdiv id\\u003d\\"hd-template\\"\\u003e\\n    #dotParse(\\u0027//starter.dotcms.com/application/themes/travel/header.vtl\\u0027)\\n   \\u003c/div\\u003e\\n   \\u003cdiv id\\u003d\\"bd-template\\"\\u003e\\n    \\u003cdiv id\\u003d\\"yui-main-template\\"\\u003e\\n     \\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody0\\"\\u003e\\n      #parseContainer(\\u0027794f91e8-d7e4-43dd-a671-1157fc983821\\u0027,\\u00271564167916555\\u0027)\\n     \\u003c/div\\u003e\\n     \\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody1\\"\\u003e\\n      #parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271564167925634\\u0027)\\n     \\u003c/div\\u003e\\n    \\u003c/div\\u003e\\n   \\u003c/div\\u003e\\n   \\u003cdiv id\\u003d\\"ft-template\\"\\u003e\\n    #dotParse(\\u0027//starter.dotcms.com/application/themes/travel/footer.vtl\\u0027)\\n   \\u003c/div\\u003e\\n  \\u003c/div\\u003e\\n \\u003c/body\\u003e\\n\\u003c/html\\u003e","image":"b8e65c6b-0d8d-44d3-bafe-7f911be52db4","drawed":true,"drawedBody":"\\u003cdiv id\\u003d\\"resp-template\\" name\\u003d\\"globalContainer\\"\\u003e\\u003cdiv id\\u003d\\"hd-template\\"\\u003e\\u003ch1\\u003eHeader\\u003c/h1\\u003e\\u003c/div\\u003e\\u003cdiv id\\u003d\\"bd-template\\"\\u003e\\u003cdiv id\\u003d\\"yui-main-template\\"\\u003e\\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody0\\"\\u003e\\u003cdiv class\\u003d\\"addContainerSpan\\"\\u003e\\u003ca href\\u003d\\"javascript: showAddContainerDialog(\\u0027splitBody0\\u0027);\\" title\\u003d\\"Add Container\\"\\u003e\\u003cspan class\\u003d\\"plusBlueIcon\\"\\u003e\\u003c/span\\u003eAdd Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cspan class\\u003d\\"titleContainerSpan\\" id\\u003d\\"splitBody0_span_794f91e8-d7e4-43dd-a671-1157fc983821_1564167916555\\" title\\u003d\\"container_794f91e8-d7e4-43dd-a671-1157fc983821\\"\\u003e\\u003cdiv class\\u003d\\"removeDiv\\"\\u003e\\u003ca href\\u003d\\"javascript: removeDrawedContainer(\\u0027splitBody0\\u0027,\\u0027794f91e8-d7e4-43dd-a671-1157fc983821\\u0027,\\u00271564167916555\\u0027);\\" title\\u003d\\"Remove Container\\"\\u003e\\u003cspan class\\u003d\\"minusIcon\\"\\u003e\\u003c/span\\u003eRemove Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"clear\\"\\u003e\\u003c/div\\u003e\\u003ch2\\u003eContainer: Breadcrumbs\\u003c/h2\\u003e\\u003cp\\u003eLorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\\u003c/p\\u003e\\u003c/span\\u003e\\u003cdiv style\\u003d\\"display: none;\\" title\\u003d\\"container_794f91e8-d7e4-43dd-a671-1157fc983821\\" id\\u003d\\"splitBody0_div_794f91e8-d7e4-43dd-a671-1157fc983821_1564167916555\\"\\u003e#parseContainer(\\u0027794f91e8-d7e4-43dd-a671-1157fc983821\\u0027,\\u00271564167916555\\u0027)\\r\\n\\u003c/div\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody1\\"\\u003e\\u003cdiv class\\u003d\\"addContainerSpan\\"\\u003e\\u003ca href\\u003d\\"javascript: showAddContainerDialog(\\u0027splitBody1\\u0027);\\" title\\u003d\\"Add Container\\"\\u003e\\u003cspan class\\u003d\\"plusBlueIcon\\"\\u003e\\u003c/span\\u003eAdd Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cspan class\\u003d\\"titleContainerSpan\\" id\\u003d\\"splitBody1_span_69b3d24d-7e80-4be6-b04a-d352d16493ee_1564167925634\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\"\\u003e\\u003cdiv class\\u003d\\"removeDiv\\"\\u003e\\u003ca href\\u003d\\"javascript: removeDrawedContainer(\\u0027splitBody1\\u0027,\\u002769b3d24d-7e80-4be6-b04a-d352d16493ee\\u0027,\\u00271564167925634\\u0027);\\" title\\u003d\\"Remove Container\\"\\u003e\\u003cspan class\\u003d\\"minusIcon\\"\\u003e\\u003c/span\\u003eRemove Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"clear\\"\\u003e\\u003c/div\\u003e\\u003ch2\\u003eContainer: Default\\u003c/h2\\u003e\\u003cp\\u003eLorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\\u003c/p\\u003e\\u003c/span\\u003e\\u003cdiv style\\u003d\\"display: none;\\" title\\u003d\\"container_69b3d24d-7e80-4be6-b04a-d352d16493ee\\" id\\u003d\\"splitBody1_div_69b3d24d-7e80-4be6-b04a-d352d16493ee_1564167925634\\"\\u003e#parseContainer(\\u0027/application/containers/default/\\u0027,\\u00271564167925634\\u0027)\\r\\n\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003cdiv id\\u003d\\"ft-template\\"\\u003e\\u003ch1\\u003eFooter\\u003c/h1\\u003e\\u003c/div\\u003e\\u003c/div\\u003e","countAddContainer":0,"countContainers":0,"theme":"d7b0ebc2-37ca-4a5a-b769-e8a3ff187661","source":"DB","title":"Default with Breadcrumbs","friendlyName":"Default template with breadcrumbs","modDate":1585198161137,"modUser":"dotcms.org.1","sortOrder":0,"showOnMenu":true,"iDate":1567002916601,"type":"template","inode":"574d6ad5-a950-432c-997c-7c1a35eefed3","identifier":"b47f4afc-7ccc-4358-a063-97763779baac"}}	1585198187863	e64a5620-9bd4-4e08-a53a-67a80079eea1
81467e1f-0c45-4b73-b515-ab0545203a8b	DELETE_LINK	{"type":"com.dotmarketing.portlets.templates.model.Template","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"PERMISSION","visibilityValue":1,"visibilityType":"java.lang.Integer"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"body":"\\u003chtml\\u003e\\n \\u003chead\\u003e\\n  #dotParse(\\u0027//demo.dotcms.com/application/themes/travel/html_head.vtl\\u0027)\\n  \\u003clink rel\\u003d\\"stylesheet\\" type\\u003d\\"text/css\\" href\\u003d\\"/html/css/template/reset-fonts-grids.css\\" /\\u003e\\n \\u003c/head\\u003e\\n \\u003cbody\\u003e\\n  \\u003cdiv id\\u003d\\"resp-template\\" name\\u003d\\"globalContainer\\"\\u003e\\n   \\u003cdiv id\\u003d\\"hd-template\\"\\u003e\\n    #dotParse(\\u0027//demo.dotcms.com/application/themes/travel/header.vtl\\u0027)\\n   \\u003c/div\\u003e\\n   \\u003cdiv id\\u003d\\"bd-template\\"\\u003e\\n    \\u003cdiv id\\u003d\\"yui-main-template\\"\\u003e\\n     \\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody0\\"\\u003e\\n      #parseContainer(\\u0027854ad819-8381-434d-a70f-6e2330985ea4\\u0027,\\u00271572981893151\\u0027)\\n     \\u003c/div\\u003e\\n    \\u003c/div\\u003e\\n   \\u003c/div\\u003e\\n   \\u003cdiv id\\u003d\\"ft-template\\"\\u003e\\n    #dotParse(\\u0027//demo.dotcms.com/application/themes/travel/footer.vtl\\u0027)\\n   \\u003c/div\\u003e\\n  \\u003c/div\\u003e\\n \\u003c/body\\u003e\\n\\u003c/html\\u003e","image":"fe0f2be1-98eb-49c7-8193-8dd178446c96","drawed":true,"drawedBody":"\\u003cdiv id\\u003d\\"resp-template\\" name\\u003d\\"globalContainer\\"\\u003e\\u003cdiv id\\u003d\\"hd-template\\"\\u003e\\u003ch1\\u003eHeader\\u003c/h1\\u003e\\u003c/div\\u003e\\u003cdiv id\\u003d\\"bd-template\\"\\u003e\\u003cdiv id\\u003d\\"yui-main-template\\"\\u003e\\u003cdiv class\\u003d\\"yui-b-template\\" id\\u003d\\"splitBody0\\"\\u003e\\u003cdiv class\\u003d\\"addContainerSpan\\"\\u003e\\u003ca href\\u003d\\"javascript: showAddContainerDialog(\\u0027splitBody0\\u0027);\\" title\\u003d\\"Add Container\\"\\u003e\\u003cspan class\\u003d\\"plusBlueIcon\\"\\u003e\\u003c/span\\u003eAdd Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cspan class\\u003d\\"titleContainerSpan\\" id\\u003d\\"splitBody0_span_854ad819-8381-434d-a70f-6e2330985ea4_1572981893151\\" title\\u003d\\"container_854ad819-8381-434d-a70f-6e2330985ea4\\"\\u003e\\u003cdiv class\\u003d\\"removeDiv\\"\\u003e\\u003ca href\\u003d\\"javascript: removeDrawedContainer(\\u0027splitBody0\\u0027,\\u0027854ad819-8381-434d-a70f-6e2330985ea4\\u0027,\\u00271572981893151\\u0027);\\" title\\u003d\\"Remove Container\\"\\u003e\\u003cspan class\\u003d\\"minusIcon\\"\\u003e\\u003c/span\\u003eRemove Container\\u003c/a\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\"clear\\"\\u003e\\u003c/div\\u003e\\u003ch2\\u003eContainer: Product Line\\u003c/h2\\u003e\\u003cp\\u003eLorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\\u003c/p\\u003e\\u003c/span\\u003e\\u003cdiv style\\u003d\\"display: none;\\" title\\u003d\\"container_854ad819-8381-434d-a70f-6e2330985ea4\\" id\\u003d\\"splitBody0_div_854ad819-8381-434d-a70f-6e2330985ea4_1572981893151\\"\\u003e#parseContainer(\\u0027854ad819-8381-434d-a70f-6e2330985ea4\\u0027,\\u00271572981893151\\u0027)\\r\\n\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\u003cdiv id\\u003d\\"ft-template\\"\\u003e\\u003ch1\\u003eFooter\\u003c/h1\\u003e\\u003c/div\\u003e\\u003c/div\\u003e","countAddContainer":0,"countContainers":0,"theme":"d7b0ebc2-37ca-4a5a-b769-e8a3ff187661","source":"DB","title":"Store - Product Line","friendlyName":"Template for listing the product lines in the store","modDate":1585198146256,"modUser":"dotcms.org.1","sortOrder":0,"showOnMenu":true,"iDate":1572981899288,"type":"template","inode":"0d0dc435-998d-439e-aad6-10cd7743f528","identifier":"52f0067c-83d9-48b6-8a74-56c6404788c7"}}	1585198190192	e64a5620-9bd4-4e08-a53a-67a80079eea1
427d48bf-4a8c-48e3-9302-625d7bf4da66	UN_PUBLISH_LINK	{"type":"com.dotmarketing.portlets.containers.model.Container","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"PERMISSION","visibilityValue":1,"visibilityType":"java.lang.Integer"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"code":"","maxContentlets":50,"useDiv":false,"sortContentletsBy":"","preLoop":"#if($EDIT_MODE \\u0026\\u0026 $CONTAINER_NOTES)\\r\\n    \\u003cdiv class\\u003d\\"alert alert-primary\\"\\u003e$CONTAINER_NOTES\\u003c/div\\u003e\\r\\n#end","postLoop":"","staticify":false,"luceneQuery":"","notes":"Please add something . . . description","source":"DB","title":"Rich Text","friendlyName":"Only takes Rich Text content type","modDate":1585198196123,"modUser":"dotcms.org.1","sortOrder":0,"showOnMenu":false,"iDate":1567004128504,"type":"containers","inode":"1dd3d033-b0e4-4ea1-b3ad-c79ab8ff838e","identifier":"d71d56b4-0a8b-4bb2-be15-ffa5a23366ea"}}	1585198196124	e64a5620-9bd4-4e08-a53a-67a80079eea1
9430643e-ebfe-4621-97d8-07495397e59f	UPDATE_PORTLET_LAYOUTS	{"type":"com.dotcms.api.system.event.Void","visibility":"GLOBAL","data":{}}	1585198310672	e64a5620-9bd4-4e08-a53a-67a80079eea1
bfa479cb-e6fd-4b97-9096-1d35151a18f5	UN_PUBLISH_LINK	{"type":"com.dotmarketing.portlets.containers.model.Container","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"PERMISSION","visibilityValue":1,"visibilityType":"java.lang.Integer"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"code":"","maxContentlets":1,"useDiv":false,"sortContentletsBy":"","preLoop":"","postLoop":"","staticify":false,"luceneQuery":"","notes":"","source":"DB","title":"Banner","friendlyName":"Image banner and text for page hero","modDate":1585198199965,"modUser":"dotcms.org.1","sortOrder":0,"showOnMenu":false,"iDate":1579107954785,"type":"containers","inode":"386ca94e-f7fe-4615-9aa2-799f9f7fb25b","identifier":"5a07f889-4536-4956-aa6e-e7967969ec3f"}}	1585198199966	e64a5620-9bd4-4e08-a53a-67a80079eea1
5dd6e601-8a79-4fc2-962e-85a67b614af2	UN_PUBLISH_LINK	{"type":"com.dotmarketing.portlets.containers.model.Container","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"PERMISSION","visibilityValue":1,"visibilityType":"java.lang.Integer"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"code":"","maxContentlets":20,"useDiv":false,"sortContentletsBy":"","preLoop":"\\u003cdiv class\\u003d\\"card-group-custom card-group-corporate\\" id\\u003d\\"accordion1\\" role\\u003d\\"tablist\\" aria-multiselectable\\u003d\\"false\\"\\u003e","postLoop":"\\u003c/div\\u003e","staticify":false,"luceneQuery":"","notes":"","source":"DB","title":"FAQ","friendlyName":"","modDate":1585198202843,"modUser":"dotcms.org.1","sortOrder":0,"showOnMenu":false,"iDate":1578429879110,"type":"containers","inode":"4b737156-d8c0-4cd8-ab1b-674cf58d22d9","identifier":"eba434c6-e67a-4a64-9c88-1faffcafb40d"}}	1585198202844	e64a5620-9bd4-4e08-a53a-67a80079eea1
8f1243ff-1930-4f1f-b3ce-d3d2e068cb51	UN_PUBLISH_LINK	{"type":"com.dotmarketing.portlets.containers.model.Container","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"PERMISSION","visibilityValue":1,"visibilityType":"java.lang.Integer"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"code":"#dotParse(\\u0027/application/vtl/breadcrumbs/breadcrumbs.vtl\\u0027)","maxContentlets":0,"useDiv":false,"sortContentletsBy":"","preLoop":"","postLoop":"","staticify":false,"luceneQuery":"","notes":"","source":"DB","title":"Breadcrumbs","friendlyName":"Breadcrumbs with background image below top nav","modDate":1585198205703,"modUser":"dotcms.org.1","sortOrder":0,"showOnMenu":false,"iDate":1569962088877,"type":"containers","inode":"395145e8-8c85-47c5-918c-7139d4552975","identifier":"794f91e8-d7e4-43dd-a671-1157fc983821"}}	1585198205704	e64a5620-9bd4-4e08-a53a-67a80079eea1
09b76239-be36-4aeb-8cac-730829747f08	UN_PUBLISH_LINK	{"type":"com.dotmarketing.portlets.containers.model.Container","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"PERMISSION","visibilityValue":1,"visibilityType":"java.lang.Integer"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"code":"#dotParse(\\"/application/vtl/store/product-line-container.vtl\\")","maxContentlets":0,"useDiv":false,"sortContentletsBy":"","preLoop":"","postLoop":"","staticify":false,"luceneQuery":"","notes":"","source":"DB","title":"Product Line","friendlyName":"Used in store template to List all of the product lines","modDate":1585198208404,"modUser":"dotcms.org.1","sortOrder":0,"showOnMenu":false,"iDate":1567004201530,"type":"containers","inode":"1c405844-fb05-4fd7-bf54-95ddb97dab30","identifier":"854ad819-8381-434d-a70f-6e2330985ea4"}}	1585198208404	e64a5620-9bd4-4e08-a53a-67a80079eea1
6a7501d3-fd74-4b7d-9a17-92eba782dbe5	ARCHIVE_LINK	{"type":"com.dotmarketing.portlets.containers.model.Container","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"PERMISSION","visibilityValue":1,"visibilityType":"java.lang.Integer"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"code":"#dotParse(\\"/application/vtl/store/product-line-container.vtl\\")","maxContentlets":0,"useDiv":false,"sortContentletsBy":"","preLoop":"","postLoop":"","staticify":false,"luceneQuery":"","notes":"","source":"DB","title":"Product Line","friendlyName":"Used in store template to List all of the product lines","modDate":1585198217707,"modUser":"dotcms.org.1","sortOrder":0,"showOnMenu":false,"iDate":1567004201530,"type":"containers","inode":"1c405844-fb05-4fd7-bf54-95ddb97dab30","identifier":"854ad819-8381-434d-a70f-6e2330985ea4"}}	1585198217709	e64a5620-9bd4-4e08-a53a-67a80079eea1
4790dad5-b4b1-4729-9a77-35ea4aab99ca	ARCHIVE_LINK	{"type":"com.dotmarketing.portlets.containers.model.Container","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"PERMISSION","visibilityValue":1,"visibilityType":"java.lang.Integer"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"code":"#dotParse(\\u0027/application/vtl/breadcrumbs/breadcrumbs.vtl\\u0027)","maxContentlets":0,"useDiv":false,"sortContentletsBy":"","preLoop":"","postLoop":"","staticify":false,"luceneQuery":"","notes":"","source":"DB","title":"Breadcrumbs","friendlyName":"Breadcrumbs with background image below top nav","modDate":1585198220698,"modUser":"dotcms.org.1","sortOrder":0,"showOnMenu":false,"iDate":1569962088877,"type":"containers","inode":"395145e8-8c85-47c5-918c-7139d4552975","identifier":"794f91e8-d7e4-43dd-a671-1157fc983821"}}	1585198220700	e64a5620-9bd4-4e08-a53a-67a80079eea1
a97a9d47-b696-4495-ad4d-aed823325fea	ARCHIVE_LINK	{"type":"com.dotmarketing.portlets.containers.model.Container","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"PERMISSION","visibilityValue":1,"visibilityType":"java.lang.Integer"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"code":"","maxContentlets":20,"useDiv":false,"sortContentletsBy":"","preLoop":"\\u003cdiv class\\u003d\\"card-group-custom card-group-corporate\\" id\\u003d\\"accordion1\\" role\\u003d\\"tablist\\" aria-multiselectable\\u003d\\"false\\"\\u003e","postLoop":"\\u003c/div\\u003e","staticify":false,"luceneQuery":"","notes":"","source":"DB","title":"FAQ","friendlyName":"","modDate":1585198223725,"modUser":"dotcms.org.1","sortOrder":0,"showOnMenu":false,"iDate":1578429879110,"type":"containers","inode":"4b737156-d8c0-4cd8-ab1b-674cf58d22d9","identifier":"eba434c6-e67a-4a64-9c88-1faffcafb40d"}}	1585198223728	e64a5620-9bd4-4e08-a53a-67a80079eea1
32ef9da7-4df5-4461-9fbe-ab11cf9de8b8	ARCHIVE_LINK	{"type":"com.dotmarketing.portlets.containers.model.Container","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"PERMISSION","visibilityValue":1,"visibilityType":"java.lang.Integer"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"code":"","maxContentlets":1,"useDiv":false,"sortContentletsBy":"","preLoop":"","postLoop":"","staticify":false,"luceneQuery":"","notes":"","source":"DB","title":"Banner","friendlyName":"Image banner and text for page hero","modDate":1585198226897,"modUser":"dotcms.org.1","sortOrder":0,"showOnMenu":false,"iDate":1579107954785,"type":"containers","inode":"386ca94e-f7fe-4615-9aa2-799f9f7fb25b","identifier":"5a07f889-4536-4956-aa6e-e7967969ec3f"}}	1585198226899	e64a5620-9bd4-4e08-a53a-67a80079eea1
834a22c0-696e-412e-9c39-c770c2c84aa7	UPDATE_PORTLET_LAYOUTS	{"type":"com.dotcms.api.system.event.Void","visibility":"GLOBAL","data":{}}	1585198305993	e64a5620-9bd4-4e08-a53a-67a80079eea1
eda8e351-8dcb-4253-a137-2c39c459e008	ARCHIVE_LINK	{"type":"com.dotmarketing.portlets.containers.model.Container","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"PERMISSION","visibilityValue":1,"visibilityType":"java.lang.Integer"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"code":"","maxContentlets":50,"useDiv":false,"sortContentletsBy":"","preLoop":"#if($EDIT_MODE \\u0026\\u0026 $CONTAINER_NOTES)\\r\\n    \\u003cdiv class\\u003d\\"alert alert-primary\\"\\u003e$CONTAINER_NOTES\\u003c/div\\u003e\\r\\n#end","postLoop":"","staticify":false,"luceneQuery":"","notes":"Please add something . . . description","source":"DB","title":"Rich Text","friendlyName":"Only takes Rich Text content type","modDate":1585198229957,"modUser":"dotcms.org.1","sortOrder":0,"showOnMenu":false,"iDate":1567004128504,"type":"containers","inode":"1dd3d033-b0e4-4ea1-b3ad-c79ab8ff838e","identifier":"d71d56b4-0a8b-4bb2-be15-ffa5a23366ea"}}	1585198229959	e64a5620-9bd4-4e08-a53a-67a80079eea1
f259b952-9f7d-4439-b860-b4016d423526	DELETE_LINK	{"type":"com.dotmarketing.portlets.containers.model.Container","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"PERMISSION","visibilityValue":1,"visibilityType":"java.lang.Integer"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"code":"","maxContentlets":50,"useDiv":false,"sortContentletsBy":"","preLoop":"#if($EDIT_MODE \\u0026\\u0026 $CONTAINER_NOTES)\\r\\n    \\u003cdiv class\\u003d\\"alert alert-primary\\"\\u003e$CONTAINER_NOTES\\u003c/div\\u003e\\r\\n#end","postLoop":"","staticify":false,"luceneQuery":"","notes":"Please add something . . . description","source":"DB","title":"Rich Text","friendlyName":"Only takes Rich Text content type","modDate":1585198229957,"modUser":"dotcms.org.1","sortOrder":0,"showOnMenu":false,"iDate":1567004128504,"type":"containers","inode":"1dd3d033-b0e4-4ea1-b3ad-c79ab8ff838e","identifier":"d71d56b4-0a8b-4bb2-be15-ffa5a23366ea"}}	1585198235523	e64a5620-9bd4-4e08-a53a-67a80079eea1
dd7d90f0-2552-452d-aa27-756d80586549	DELETE_LINK	{"type":"com.dotmarketing.portlets.containers.model.Container","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"PERMISSION","visibilityValue":1,"visibilityType":"java.lang.Integer"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"code":"","maxContentlets":1,"useDiv":false,"sortContentletsBy":"","preLoop":"","postLoop":"","staticify":false,"luceneQuery":"","notes":"","source":"DB","title":"Banner","friendlyName":"Image banner and text for page hero","modDate":1585198226897,"modUser":"dotcms.org.1","sortOrder":0,"showOnMenu":false,"iDate":1579107954785,"type":"containers","inode":"386ca94e-f7fe-4615-9aa2-799f9f7fb25b","identifier":"5a07f889-4536-4956-aa6e-e7967969ec3f"}}	1585198237664	e64a5620-9bd4-4e08-a53a-67a80079eea1
5dc444c7-91d1-4792-964e-5291b08ce5e4	DELETE_LINK	{"type":"com.dotmarketing.portlets.containers.model.Container","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"PERMISSION","visibilityValue":1,"visibilityType":"java.lang.Integer"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"code":"","maxContentlets":20,"useDiv":false,"sortContentletsBy":"","preLoop":"\\u003cdiv class\\u003d\\"card-group-custom card-group-corporate\\" id\\u003d\\"accordion1\\" role\\u003d\\"tablist\\" aria-multiselectable\\u003d\\"false\\"\\u003e","postLoop":"\\u003c/div\\u003e","staticify":false,"luceneQuery":"","notes":"","source":"DB","title":"FAQ","friendlyName":"","modDate":1585198223725,"modUser":"dotcms.org.1","sortOrder":0,"showOnMenu":false,"iDate":1578429879110,"type":"containers","inode":"4b737156-d8c0-4cd8-ab1b-674cf58d22d9","identifier":"eba434c6-e67a-4a64-9c88-1faffcafb40d"}}	1585198240011	e64a5620-9bd4-4e08-a53a-67a80079eea1
68049914-4b74-4cb2-be3c-d7d6db00e39c	DELETE_LINK	{"type":"com.dotmarketing.portlets.containers.model.Container","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"PERMISSION","visibilityValue":1,"visibilityType":"java.lang.Integer"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"code":"#dotParse(\\u0027/application/vtl/breadcrumbs/breadcrumbs.vtl\\u0027)","maxContentlets":0,"useDiv":false,"sortContentletsBy":"","preLoop":"","postLoop":"","staticify":false,"luceneQuery":"","notes":"","source":"DB","title":"Breadcrumbs","friendlyName":"Breadcrumbs with background image below top nav","modDate":1585198220698,"modUser":"dotcms.org.1","sortOrder":0,"showOnMenu":false,"iDate":1569962088877,"type":"containers","inode":"395145e8-8c85-47c5-918c-7139d4552975","identifier":"794f91e8-d7e4-43dd-a671-1157fc983821"}}	1585198242248	e64a5620-9bd4-4e08-a53a-67a80079eea1
ccf9a53f-774b-4b6c-abc3-7a75ba8fb37d	DELETE_LINK	{"type":"com.dotmarketing.portlets.containers.model.Container","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"PERMISSION","visibilityValue":1,"visibilityType":"java.lang.Integer"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"code":"#dotParse(\\"/application/vtl/store/product-line-container.vtl\\")","maxContentlets":0,"useDiv":false,"sortContentletsBy":"","preLoop":"","postLoop":"","staticify":false,"luceneQuery":"","notes":"","source":"DB","title":"Product Line","friendlyName":"Used in store template to List all of the product lines","modDate":1585198217707,"modUser":"dotcms.org.1","sortOrder":0,"showOnMenu":false,"iDate":1567004201530,"type":"containers","inode":"1c405844-fb05-4fd7-bf54-95ddb97dab30","identifier":"854ad819-8381-434d-a70f-6e2330985ea4"}}	1585198244388	e64a5620-9bd4-4e08-a53a-67a80079eea1
442b800c-170f-44ba-9492-c7f215043baa	DELETE_LINK	{"type":"com.dotmarketing.portlets.containers.model.Container","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"PERMISSION","visibilityValue":1,"visibilityType":"java.lang.Integer"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"code":"","maxContentlets":10,"useDiv":false,"sortContentletsBy":"","preLoop":"#if($EDIT_MODE \\u0026\\u0026 $CONTAINER_NOTES)\\r\\n    \\u003cdiv class\\u003d\\"container-notes\\"\\u003e$CONTAINER_NOTES\\u003c/div\\u003e\\r\\n#end","postLoop":"","staticify":false,"luceneQuery":"","notes":"Default Container","source":"DB","title":"Default Container","friendlyName":"Default container for multiple content types","modDate":1562016205886,"modUser":"dotcms.org.1","sortOrder":0,"showOnMenu":false,"iDate":1558100120648,"type":"containers","inode":"79f9de3e-be70-41be-808f-7569d516d5a2","identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1"}}	1585198246710	e64a5620-9bd4-4e08-a53a-67a80079eea1
8c68d5f5-0e02-4f5d-9630-db27e19d8b3e	UPDATE_PORTLET_LAYOUTS	{"type":"com.dotcms.api.system.event.Void","visibility":"GLOBAL","data":{}}	1585198302927	e64a5620-9bd4-4e08-a53a-67a80079eea1
f98ab6df-2938-4514-8b52-4c07d915bfe4	UPDATE_PORTLET_LAYOUTS	{"type":"com.dotcms.api.system.event.Void","visibility":"GLOBAL","data":{}}	1585198308396	e64a5620-9bd4-4e08-a53a-67a80079eea1
7caef770-737c-4bb7-bb22-3945cf8afd56	UPDATE_PORTLET_LAYOUTS	{"type":"com.dotcms.api.system.event.Void","visibility":"GLOBAL","data":{}}	1585198313173	e64a5620-9bd4-4e08-a53a-67a80079eea1
ce2ad557-f769-4025-9e3f-8a3d7b3e6d37	UPDATE_PORTLET_LAYOUTS	{"type":"com.dotcms.api.system.event.Void","visibility":"GLOBAL","data":{}}	1585198322211	e64a5620-9bd4-4e08-a53a-67a80079eea1
a9ae89ed-a6ea-41fb-82e7-7a48fd357cee	UPDATE_PORTLET_LAYOUTS	{"type":"com.dotcms.api.system.event.Void","visibility":"GLOBAL","data":{}}	1585198343365	e64a5620-9bd4-4e08-a53a-67a80079eea1
11ef7545-0d65-4fa0-9fc8-77bd7894620b	DELETE_LINK	{"type":"com.dotmarketing.portlets.containers.model.Container","visibility":"EXCLUDE_OWNER","visibilityValue":{"userId":"dotcms.org.1","visibility":"PERMISSION","visibilityValue":1,"visibilityType":"java.lang.Integer"},"visibilityType":"com.dotcms.api.system.event.verifier.ExcludeOwnerVerifierBean","data":{"code":"","maxContentlets":25,"useDiv":false,"sortContentletsBy":"","preLoop":"\\u003cdiv class\\u003d\\"large-column\\"\\u003e","postLoop":"\\u003c/div\\u003e","staticify":false,"luceneQuery":"","notes":"    Large Column:\\r\\n    - Blog\\r\\n    - Events\\r\\n    - Generic\\r\\n    - Location\\r\\n    - Media\\r\\n    - News\\r\\n    - Documents\\r\\n    - Products","source":"DB","title":"Large Column (lg-1)","friendlyName":"Large body column container","modDate":1558125872868,"modUser":"dotcms.org.1","sortOrder":0,"showOnMenu":false,"iDate":1523037174390,"type":"containers","inode":"e58e92b3-7135-461b-b56b-04ff143a389b","identifier":"56bd55ea-b04b-480d-9e37-5d6f9217dcc3"}}	1585198248623	e64a5620-9bd4-4e08-a53a-67a80079eea1
63c6af75-0e65-4225-85cc-9271fb1b6010	UPDATE_PORTLET_LAYOUTS	{"type":"com.dotcms.api.system.event.Void","visibility":"GLOBAL","data":{}}	1585198330374	e64a5620-9bd4-4e08-a53a-67a80079eea1
4d946868-fd9c-4a0b-9319-846c113db9af	UPDATE_PORTLET_LAYOUTS	{"type":"com.dotcms.api.system.event.Void","visibility":"GLOBAL","data":{}}	1585198331940	e64a5620-9bd4-4e08-a53a-67a80079eea1
25744371-6724-4905-b804-b3e10e4ae852	UPDATE_PORTLET_LAYOUTS	{"type":"com.dotcms.api.system.event.Void","visibility":"GLOBAL","data":{}}	1585198333784	e64a5620-9bd4-4e08-a53a-67a80079eea1
d8d6cd67-01ac-4ba7-a247-9d197a2e3c8e	UPDATE_PORTLET_LAYOUTS	{"type":"com.dotcms.api.system.event.Void","visibility":"GLOBAL","data":{}}	1585198337038	e64a5620-9bd4-4e08-a53a-67a80079eea1
115af5e5-6a8a-4802-ac70-66f69fa4e2e8	UPDATE_PORTLET_LAYOUTS	{"type":"com.dotcms.api.system.event.Void","visibility":"GLOBAL","data":{}}	1585198354237	e64a5620-9bd4-4e08-a53a-67a80079eea1
03007156-8af9-4f64-b580-3d6527a8c9c8	DELETE_BASE_CONTENT_TYPE	{"type":"com.dotcms.api.system.event.ContentTypePayloadDataWrapper","visibility":"PERMISSION","visibilityValue":"1","visibilityType":"java.lang.String","data":{"actionUrl":"/c/portal/layout?p_l_id\\u003d71b8a1ca-37b6-4b6e-a43b-c7482f28db6c\\u0026p_p_id\\u003dcontent\\u0026p_p_action\\u003d1\\u0026p_p_state\\u003dmaximized\\u0026_content_inode\\u003d\\u0026_content_referer\\u003d%2Fc%2Fportal%2Flayout%3Fp_l_id%3D71b8a1ca-37b6-4b6e-a43b-c7482f28db6c%26p_p_id%3Dcontent%26p_p_action%3D1%26p_p_state%3Dmaximized%26_content_inode%3D%26_content_structure_id%3D91812c8b-0441-4139-8d4d-7423cfb0e979%26_content_cmd%3Dnew%26_content_lang%3D1%26_content_struts_action%3D%252Fext%252Fcontentlet%252Fview_contentlets\\u0026_content_selectedStructure\\u003d91812c8b-0441-4139-8d4d-7423cfb0e979\\u0026_content_cmd\\u003dnew\\u0026_content_lang\\u003d1\\u0026_content_struts_action\\u003d%2Fext%2Fcontentlet%2Fedit_contentlet","type":{"type":"com.dotcms.contenttype.model.type.ImmutablePageContentType","data":{"name":"Destination","id":"91812c8b-0441-4139-8d4d-7423cfb0e979","description":"Travel destinations landing pages","defaultType":false,"fixed":false,"iDate":1566936026000,"system":false,"versionable":true,"multilingualable":false,"variable":"Destination","modDate":1585198521000,"host":"48190c8c-42c4-46af-8d1a-0cd5db894797","folder":"SYSTEM_FOLDER"}}}}	1585198533145	e64a5620-9bd4-4e08-a53a-67a80079eea1
cbe1b6eb-7b8e-427e-bd66-49174a4ec262	DELETE_BASE_CONTENT_TYPE	{"type":"com.dotcms.api.system.event.ContentTypePayloadDataWrapper","visibility":"PERMISSION","visibilityValue":"1","visibilityType":"java.lang.String","data":{"actionUrl":"/c/portal/layout?p_l_id\\u003d71b8a1ca-37b6-4b6e-a43b-c7482f28db6c\\u0026p_p_id\\u003dcontent\\u0026p_p_action\\u003d1\\u0026p_p_state\\u003dmaximized\\u0026_content_inode\\u003d\\u0026_content_referer\\u003d%2Fc%2Fportal%2Flayout%3Fp_l_id%3D71b8a1ca-37b6-4b6e-a43b-c7482f28db6c%26p_p_id%3Dcontent%26p_p_action%3D1%26p_p_state%3Dmaximized%26_content_inode%3D%26_content_structure_id%3Dfe719cc1-26d1-499f-8702-c6d35c661286%26_content_cmd%3Dnew%26_content_lang%3D1%26_content_struts_action%3D%252Fext%252Fcontentlet%252Fview_contentlets\\u0026_content_selectedStructure\\u003dfe719cc1-26d1-499f-8702-c6d35c661286\\u0026_content_cmd\\u003dnew\\u0026_content_lang\\u003d1\\u0026_content_struts_action\\u003d%2Fext%2Fcontentlet%2Fedit_contentlet","type":{"type":"com.dotcms.contenttype.model.type.ImmutableSimpleContentType","data":{"name":"Blog Commenter","id":"fe719cc1-26d1-499f-8702-c6d35c661286","defaultType":false,"fixed":false,"iDate":1555103168000,"system":false,"versionable":true,"multilingualable":false,"variable":"BlogCommentor","modDate":1585198531000,"host":"48190c8c-42c4-46af-8d1a-0cd5db894797","folder":"SYSTEM_FOLDER","requiredFields":[]}}}}	1585198536639	e64a5620-9bd4-4e08-a53a-67a80079eea1
eca74ac2-086a-45fd-92d5-c01b3b341cd6	DELETE_BASE_CONTENT_TYPE	{"type":"com.dotcms.api.system.event.ContentTypePayloadDataWrapper","visibility":"PERMISSION","visibilityValue":"1","visibilityType":"java.lang.String","data":{"actionUrl":"/c/portal/layout?p_l_id\\u003d71b8a1ca-37b6-4b6e-a43b-c7482f28db6c\\u0026p_p_id\\u003dcontent\\u0026p_p_action\\u003d1\\u0026p_p_state\\u003dmaximized\\u0026_content_inode\\u003d\\u0026_content_referer\\u003d%2Fc%2Fportal%2Flayout%3Fp_l_id%3D71b8a1ca-37b6-4b6e-a43b-c7482f28db6c%26p_p_id%3Dcontent%26p_p_action%3D1%26p_p_state%3Dmaximized%26_content_inode%3D%26_content_structure_id%3D3d4a8854-7696-40c2-b0f3-28c8ff1121f9%26_content_cmd%3Dnew%26_content_lang%3D1%26_content_struts_action%3D%252Fext%252Fcontentlet%252Fview_contentlets\\u0026_content_selectedStructure\\u003d3d4a8854-7696-40c2-b0f3-28c8ff1121f9\\u0026_content_cmd\\u003dnew\\u0026_content_lang\\u003d1\\u0026_content_struts_action\\u003d%2Fext%2Fcontentlet%2Fedit_contentlet","type":{"type":"com.dotcms.contenttype.model.type.ImmutableSimpleContentType","data":{"name":"FAQ","id":"3d4a8854-7696-40c2-b0f3-28c8ff1121f9","defaultType":false,"fixed":false,"iDate":1578429588000,"system":false,"versionable":true,"multilingualable":false,"variable":"FAQ","modDate":1585197315000,"host":"48190c8c-42c4-46af-8d1a-0cd5db894797","folder":"SYSTEM_FOLDER","requiredFields":[]}}}}	1585198541428	e64a5620-9bd4-4e08-a53a-67a80079eea1
52f115cc-d87f-40f7-95f8-50590835e399	DELETE_BASE_CONTENT_TYPE	{"type":"com.dotcms.api.system.event.ContentTypePayloadDataWrapper","visibility":"PERMISSION","visibilityValue":"1","visibilityType":"java.lang.String","data":{"actionUrl":"/c/portal/layout?p_l_id\\u003d71b8a1ca-37b6-4b6e-a43b-c7482f28db6c\\u0026p_p_id\\u003dcontent\\u0026p_p_action\\u003d1\\u0026p_p_state\\u003dmaximized\\u0026_content_inode\\u003d\\u0026_content_referer\\u003d%2Fc%2Fportal%2Flayout%3Fp_l_id%3D71b8a1ca-37b6-4b6e-a43b-c7482f28db6c%26p_p_id%3Dcontent%26p_p_action%3D1%26p_p_state%3Dmaximized%26_content_inode%3D%26_content_structure_id%3Dce7295c8-df36-46c0-9c98-2fb764e9ec1c%26_content_cmd%3Dnew%26_content_lang%3D1%26_content_struts_action%3D%252Fext%252Fcontentlet%252Fview_contentlets\\u0026_content_selectedStructure\\u003dce7295c8-df36-46c0-9c98-2fb764e9ec1c\\u0026_content_cmd\\u003dnew\\u0026_content_lang\\u003d1\\u0026_content_struts_action\\u003d%2Fext%2Fcontentlet%2Fedit_contentlet","type":{"type":"com.dotcms.contenttype.model.type.ImmutableSimpleContentType","data":{"name":"Call to Action","id":"ce7295c8-df36-46c0-9c98-2fb764e9ec1c","description":"Headline, description with call to action button","defaultType":false,"fixed":false,"iDate":1570454538000,"system":false,"versionable":true,"multilingualable":false,"variable":"CallToAction","modDate":1585197309000,"host":"48190c8c-42c4-46af-8d1a-0cd5db894797","folder":"SYSTEM_FOLDER","requiredFields":[]}}}}	1585198546639	e64a5620-9bd4-4e08-a53a-67a80079eea1
b0c8e150-293f-490c-a6ac-a1bea520fc81	NOTIFICATION	{"type":"com.dotcms.notifications.bean.Notification","visibility":"ROLE","visibilityValue":"892ab105-f212-407f-8fb4-58ec59310a5e","visibilityType":"java.lang.String","data":{"groupId":"ebfa87e2-66ef-4d8d-8d9e-5fcfed2ecbc3","notificationData":{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}},"level":"INFO","userId":"system","timeSent":1585198482003,"wasRead":false,"prettyDate":"seconds ago"}}	1585198482003	e64a5620-9bd4-4e08-a53a-67a80079eea1
d996dfad-9511-4240-b6f8-900e5754afc1	NOTIFICATION	{"type":"com.dotcms.notifications.bean.Notification","visibility":"ROLE","visibilityValue":"892ab105-f212-407f-8fb4-58ec59310a5e","visibilityType":"java.lang.String","data":{"groupId":"3e84d1ae-e007-438c-9a2f-551e8e654b06","notificationData":{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}},"level":"INFO","userId":"system","timeSent":1585198485507,"wasRead":false,"prettyDate":"seconds ago"}}	1585198485507	e64a5620-9bd4-4e08-a53a-67a80079eea1
9742e27c-4876-41ae-b3b0-74a757d90e78	NOTIFICATION	{"type":"com.dotcms.notifications.bean.Notification","visibility":"ROLE","visibilityValue":"892ab105-f212-407f-8fb4-58ec59310a5e","visibilityType":"java.lang.String","data":{"groupId":"750c84a1-f050-4262-8a2e-abb213baf367","notificationData":{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}},"level":"INFO","userId":"system","timeSent":1585198489009,"wasRead":false,"prettyDate":"seconds ago"}}	1585198489009	e64a5620-9bd4-4e08-a53a-67a80079eea1
96160a81-2cb3-447f-a968-0501bff2fa4b	NOTIFICATION	{"type":"com.dotcms.notifications.bean.Notification","visibility":"ROLE","visibilityValue":"892ab105-f212-407f-8fb4-58ec59310a5e","visibilityType":"java.lang.String","data":{"groupId":"ff893cdc-a013-4f4e-8562-7a8dc2e22dbd","notificationData":{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}},"level":"INFO","userId":"system","timeSent":1585198489582,"wasRead":false,"prettyDate":"seconds ago"}}	1585198489582	e64a5620-9bd4-4e08-a53a-67a80079eea1
2a17c592-a2a0-4c85-9a36-dc75c0952e74	DELETE_BASE_CONTENT_TYPE	{"type":"com.dotcms.api.system.event.ContentTypePayloadDataWrapper","visibility":"PERMISSION","visibilityValue":"1","visibilityType":"java.lang.String","data":{"actionUrl":"/c/portal/layout?p_l_id\\u003d71b8a1ca-37b6-4b6e-a43b-c7482f28db6c\\u0026p_p_id\\u003dcontent\\u0026p_p_action\\u003d1\\u0026p_p_state\\u003dmaximized\\u0026_content_inode\\u003d\\u0026_content_referer\\u003d%2Fc%2Fportal%2Flayout%3Fp_l_id%3D71b8a1ca-37b6-4b6e-a43b-c7482f28db6c%26p_p_id%3Dcontent%26p_p_action%3D1%26p_p_state%3Dmaximized%26_content_inode%3D%26_content_structure_id%3D799f176a-d32e-4844-a07c-1b5fcd107578%26_content_cmd%3Dnew%26_content_lang%3D1%26_content_struts_action%3D%252Fext%252Fcontentlet%252Fview_contentlets\\u0026_content_selectedStructure\\u003d799f176a-d32e-4844-a07c-1b5fcd107578\\u0026_content_cmd\\u003dnew\\u0026_content_lang\\u003d1\\u0026_content_struts_action\\u003d%2Fext%2Fcontentlet%2Fedit_contentlet","type":{"type":"com.dotcms.contenttype.model.type.ImmutableSimpleContentType","data":{"name":"Blog","id":"799f176a-d32e-4844-a07c-1b5fcd107578","description":"Travel Blog","defaultType":false,"fixed":false,"iDate":1543419364000,"system":false,"versionable":true,"multilingualable":false,"variable":"Blog","publishDateVar":"postingDate","modDate":1585197893000,"host":"SYSTEM_HOST","folder":"SYSTEM_FOLDER","requiredFields":[]}}}}	1585198525910	e64a5620-9bd4-4e08-a53a-67a80079eea1
d6bb0f83-7124-4ede-874a-ef19362264ec	DELETE_BASE_CONTENT_TYPE	{"type":"com.dotcms.api.system.event.ContentTypePayloadDataWrapper","visibility":"PERMISSION","visibilityValue":"1","visibilityType":"java.lang.String","data":{"actionUrl":"/c/portal/layout?p_l_id\\u003d71b8a1ca-37b6-4b6e-a43b-c7482f28db6c\\u0026p_p_id\\u003dcontent\\u0026p_p_action\\u003d1\\u0026p_p_state\\u003dmaximized\\u0026_content_inode\\u003d\\u0026_content_referer\\u003d%2Fc%2Fportal%2Flayout%3Fp_l_id%3D71b8a1ca-37b6-4b6e-a43b-c7482f28db6c%26p_p_id%3Dcontent%26p_p_action%3D1%26p_p_state%3Dmaximized%26_content_inode%3D%26_content_structure_id%3D045d0b52-fa68-465a-b820-f9fc22febc50%26_content_cmd%3Dnew%26_content_lang%3D1%26_content_struts_action%3D%252Fext%252Fcontentlet%252Fview_contentlets\\u0026_content_selectedStructure\\u003d045d0b52-fa68-465a-b820-f9fc22febc50\\u0026_content_cmd\\u003dnew\\u0026_content_lang\\u003d1\\u0026_content_struts_action\\u003d%2Fext%2Fcontentlet%2Fedit_contentlet","type":{"type":"com.dotcms.contenttype.model.type.ImmutableSimpleContentType","data":{"name":"Blog Author","id":"045d0b52-fa68-465a-b820-f9fc22febc50","defaultType":false,"fixed":false,"iDate":1555086385000,"system":false,"versionable":true,"multilingualable":false,"variable":"BlogAuthor","modDate":1585198526000,"host":"SYSTEM_HOST","folder":"SYSTEM_FOLDER","requiredFields":[]}}}}	1585198528674	e64a5620-9bd4-4e08-a53a-67a80079eea1
ebbfb70d-9021-4c0b-9609-9567ec0da85b	DELETE_BASE_CONTENT_TYPE	{"type":"com.dotcms.api.system.event.ContentTypePayloadDataWrapper","visibility":"PERMISSION","visibilityValue":"1","visibilityType":"java.lang.String","data":{"actionUrl":"/c/portal/layout?p_l_id\\u003d71b8a1ca-37b6-4b6e-a43b-c7482f28db6c\\u0026p_p_id\\u003dcontent\\u0026p_p_action\\u003d1\\u0026p_p_state\\u003dmaximized\\u0026_content_inode\\u003d\\u0026_content_referer\\u003d%2Fc%2Fportal%2Flayout%3Fp_l_id%3D71b8a1ca-37b6-4b6e-a43b-c7482f28db6c%26p_p_id%3Dcontent%26p_p_action%3D1%26p_p_state%3Dmaximized%26_content_inode%3D%26_content_structure_id%3D6044a806-f462-4977-a353-57539eac2a2c%26_content_cmd%3Dnew%26_content_lang%3D1%26_content_struts_action%3D%252Fext%252Fcontentlet%252Fview_contentlets\\u0026_content_selectedStructure\\u003d6044a806-f462-4977-a353-57539eac2a2c\\u0026_content_cmd\\u003dnew\\u0026_content_lang\\u003d1\\u0026_content_struts_action\\u003d%2Fext%2Fcontentlet%2Fedit_contentlet","type":{"type":"com.dotcms.contenttype.model.type.ImmutableSimpleContentType","data":{"name":"Blog Comment","id":"6044a806-f462-4977-a353-57539eac2a2c","defaultType":false,"fixed":false,"iDate":1555017311000,"system":false,"versionable":true,"multilingualable":false,"variable":"BlogComment","modDate":1585198526000,"host":"48190c8c-42c4-46af-8d1a-0cd5db894797","folder":"SYSTEM_FOLDER","requiredFields":[]}}}}	1585198530746	e64a5620-9bd4-4e08-a53a-67a80079eea1
2cb3d1e3-41a7-4f6f-9ebb-4af0df3f057b	DELETE_BASE_CONTENT_TYPE	{"type":"com.dotcms.api.system.event.ContentTypePayloadDataWrapper","visibility":"PERMISSION","visibilityValue":"1","visibilityType":"java.lang.String","data":{"actionUrl":"/c/portal/layout?p_l_id\\u003d71b8a1ca-37b6-4b6e-a43b-c7482f28db6c\\u0026p_p_id\\u003dcontent\\u0026p_p_action\\u003d1\\u0026p_p_state\\u003dmaximized\\u0026_content_inode\\u003d\\u0026_content_referer\\u003d%2Fc%2Fportal%2Flayout%3Fp_l_id%3D71b8a1ca-37b6-4b6e-a43b-c7482f28db6c%26p_p_id%3Dcontent%26p_p_action%3D1%26p_p_state%3Dmaximized%26_content_inode%3D%26_content_structure_id%3D98752499-7367-43ac-ba44-2723919a3a56%26_content_cmd%3Dnew%26_content_lang%3D1%26_content_struts_action%3D%252Fext%252Fcontentlet%252Fview_contentlets\\u0026_content_selectedStructure\\u003d98752499-7367-43ac-ba44-2723919a3a56\\u0026_content_cmd\\u003dnew\\u0026_content_lang\\u003d1\\u0026_content_struts_action\\u003d%2Fext%2Fcontentlet%2Fedit_contentlet","type":{"type":"com.dotcms.contenttype.model.type.ImmutableWidgetContentType","data":{"multilingualable":false,"name":"FAQ Widget","id":"98752499-7367-43ac-ba44-2723919a3a56","defaultType":false,"fixed":false,"iDate":1578676533000,"system":false,"versionable":true,"variable":"FaqWidget","modDate":1585197315000,"host":"48190c8c-42c4-46af-8d1a-0cd5db894797","folder":"SYSTEM_FOLDER"}}}}	1585198539664	e64a5620-9bd4-4e08-a53a-67a80079eea1
ad084ad7-fea4-4d2d-9933-1510dfde4aa0	DELETE_BASE_CONTENT_TYPE	{"type":"com.dotcms.api.system.event.ContentTypePayloadDataWrapper","visibility":"PERMISSION","visibilityValue":"1","visibilityType":"java.lang.String","data":{"actionUrl":"/c/portal/layout?p_l_id\\u003d71b8a1ca-37b6-4b6e-a43b-c7482f28db6c\\u0026p_p_id\\u003dcontent\\u0026p_p_action\\u003d1\\u0026p_p_state\\u003dmaximized\\u0026_content_inode\\u003d\\u0026_content_referer\\u003d%2Fc%2Fportal%2Flayout%3Fp_l_id%3D71b8a1ca-37b6-4b6e-a43b-c7482f28db6c%26p_p_id%3Dcontent%26p_p_action%3D1%26p_p_state%3Dmaximized%26_content_inode%3D%26_content_structure_id%3Da1661fbc-9e84-4c00-bd62-76d633170da3%26_content_cmd%3Dnew%26_content_lang%3D1%26_content_struts_action%3D%252Fext%252Fcontentlet%252Fview_contentlets\\u0026_content_selectedStructure\\u003da1661fbc-9e84-4c00-bd62-76d633170da3\\u0026_content_cmd\\u003dnew\\u0026_content_lang\\u003d1\\u0026_content_struts_action\\u003d%2Fext%2Fcontentlet%2Fedit_contentlet","type":{"type":"com.dotcms.contenttype.model.type.ImmutableSimpleContentType","data":{"name":"Product","id":"a1661fbc-9e84-4c00-bd62-76d633170da3","defaultType":false,"fixed":false,"iDate":1562940705000,"system":false,"versionable":true,"multilingualable":false,"variable":"Product","modDate":1585197946000,"host":"48190c8c-42c4-46af-8d1a-0cd5db894797","folder":"SYSTEM_FOLDER","requiredFields":[]}}}}	1585198515679	e64a5620-9bd4-4e08-a53a-67a80079eea1
92ca9f16-e7a5-4243-a57a-1367a443dbf6	DELETE_BASE_CONTENT_TYPE	{"type":"com.dotcms.api.system.event.ContentTypePayloadDataWrapper","visibility":"PERMISSION","visibilityValue":"1","visibilityType":"java.lang.String","data":{"actionUrl":"/c/portal/layout?p_l_id\\u003d71b8a1ca-37b6-4b6e-a43b-c7482f28db6c\\u0026p_p_id\\u003dcontent\\u0026p_p_action\\u003d1\\u0026p_p_state\\u003dmaximized\\u0026_content_inode\\u003d\\u0026_content_referer\\u003d%2Fc%2Fportal%2Flayout%3Fp_l_id%3D71b8a1ca-37b6-4b6e-a43b-c7482f28db6c%26p_p_id%3Dcontent%26p_p_action%3D1%26p_p_state%3Dmaximized%26_content_inode%3D%26_content_structure_id%3D778f3246-9b11-4a2a-a101-e7fdf111bdad%26_content_cmd%3Dnew%26_content_lang%3D1%26_content_struts_action%3D%252Fext%252Fcontentlet%252Fview_contentlets\\u0026_content_selectedStructure\\u003d778f3246-9b11-4a2a-a101-e7fdf111bdad\\u0026_content_cmd\\u003dnew\\u0026_content_lang\\u003d1\\u0026_content_struts_action\\u003d%2Fext%2Fcontentlet%2Fedit_contentlet","type":{"type":"com.dotcms.contenttype.model.type.ImmutableSimpleContentType","data":{"name":"Activity","id":"778f3246-9b11-4a2a-a101-e7fdf111bdad","description":"Activities available at desitnations","defaultType":false,"fixed":false,"iDate":1567778770000,"system":false,"versionable":true,"multilingualable":false,"variable":"Activity","modDate":1585197920000,"host":"48190c8c-42c4-46af-8d1a-0cd5db894797","folder":"SYSTEM_FOLDER","requiredFields":[]}}}}	1585198520723	e64a5620-9bd4-4e08-a53a-67a80079eea1
b4f146c8-5089-454b-9f5b-d1151016adb8	DELETE_BASE_CONTENT_TYPE	{"type":"com.dotcms.api.system.event.ContentTypePayloadDataWrapper","visibility":"PERMISSION","visibilityValue":"1","visibilityType":"java.lang.String","data":{"actionUrl":"/c/portal/layout?p_l_id\\u003d71b8a1ca-37b6-4b6e-a43b-c7482f28db6c\\u0026p_p_id\\u003dcontent\\u0026p_p_action\\u003d1\\u0026p_p_state\\u003dmaximized\\u0026_content_inode\\u003d\\u0026_content_referer\\u003d%2Fc%2Fportal%2Flayout%3Fp_l_id%3D71b8a1ca-37b6-4b6e-a43b-c7482f28db6c%26p_p_id%3Dcontent%26p_p_action%3D1%26p_p_state%3Dmaximized%26_content_inode%3D%26_content_structure_id%3Df52275b5-7595-4f89-8375-8bb1266437a5%26_content_cmd%3Dnew%26_content_lang%3D1%26_content_struts_action%3D%252Fext%252Fcontentlet%252Fview_contentlets\\u0026_content_selectedStructure\\u003df52275b5-7595-4f89-8375-8bb1266437a5\\u0026_content_cmd\\u003dnew\\u0026_content_lang\\u003d1\\u0026_content_struts_action\\u003d%2Fext%2Fcontentlet%2Fedit_contentlet","type":{"type":"com.dotcms.contenttype.model.type.ImmutablePageContentType","data":{"name":"Product Line","id":"f52275b5-7595-4f89-8375-8bb1266437a5","defaultType":false,"fixed":false,"iDate":1564518971000,"system":false,"versionable":true,"multilingualable":false,"variable":"ProductLineLandingPage","modDate":1585197312000,"host":"48190c8c-42c4-46af-8d1a-0cd5db894797","folder":"SYSTEM_FOLDER"}}}}	1585198544937	e64a5620-9bd4-4e08-a53a-67a80079eea1
23ce25cd-55b9-4b31-a6ed-6bf871218071	DELETE_BASE_CONTENT_TYPE	{"type":"com.dotcms.api.system.event.ContentTypePayloadDataWrapper","visibility":"PERMISSION","visibilityValue":"1","visibilityType":"java.lang.String","data":{"actionUrl":"/c/portal/layout?p_l_id\\u003d71b8a1ca-37b6-4b6e-a43b-c7482f28db6c\\u0026p_p_id\\u003dcontent\\u0026p_p_action\\u003d1\\u0026p_p_state\\u003dmaximized\\u0026_content_inode\\u003d\\u0026_content_referer\\u003d%2Fc%2Fportal%2Flayout%3Fp_l_id%3D71b8a1ca-37b6-4b6e-a43b-c7482f28db6c%26p_p_id%3Dcontent%26p_p_action%3D1%26p_p_state%3Dmaximized%26_content_inode%3D%26_content_structure_id%3D4c441ada-944a-43af-a653-9bb4f3f0cb2b%26_content_cmd%3Dnew%26_content_lang%3D1%26_content_struts_action%3D%252Fext%252Fcontentlet%252Fview_contentlets\\u0026_content_selectedStructure\\u003d4c441ada-944a-43af-a653-9bb4f3f0cb2b\\u0026_content_cmd\\u003dnew\\u0026_content_lang\\u003d1\\u0026_content_struts_action\\u003d%2Fext%2Fcontentlet%2Fedit_contentlet","type":{"type":"com.dotcms.contenttype.model.type.ImmutableSimpleContentType","data":{"name":"Banner","id":"4c441ada-944a-43af-a653-9bb4f3f0cb2b","description":"Hero image used on homepage and landing pages","defaultType":false,"fixed":false,"iDate":1489086945734,"system":false,"versionable":true,"multilingualable":false,"variable":"Banner","modDate":1585197309000,"host":"SYSTEM_HOST","folder":"SYSTEM_FOLDER","requiredFields":[]}}}}	1585198548149	e64a5620-9bd4-4e08-a53a-67a80079eea1
3f33ff27-9a07-4ef1-9a3a-812809275f16	DELETE_BASE_CONTENT_TYPE	{"type":"com.dotcms.api.system.event.ContentTypePayloadDataWrapper","visibility":"PERMISSION","visibilityValue":"1","visibilityType":"java.lang.String","data":{"actionUrl":"/c/portal/layout?p_l_id\\u003d71b8a1ca-37b6-4b6e-a43b-c7482f28db6c\\u0026p_p_id\\u003dcontent\\u0026p_p_action\\u003d1\\u0026p_p_state\\u003dmaximized\\u0026_content_inode\\u003d\\u0026_content_referer\\u003d%2Fc%2Fportal%2Flayout%3Fp_l_id%3D71b8a1ca-37b6-4b6e-a43b-c7482f28db6c%26p_p_id%3Dcontent%26p_p_action%3D1%26p_p_state%3Dmaximized%26_content_inode%3D%26_content_structure_id%3D73061f34-7fa0-4f77-9724-5ca0013a0214%26_content_cmd%3Dnew%26_content_lang%3D1%26_content_struts_action%3D%252Fext%252Fcontentlet%252Fview_contentlets\\u0026_content_selectedStructure\\u003d73061f34-7fa0-4f77-9724-5ca0013a0214\\u0026_content_cmd\\u003dnew\\u0026_content_lang\\u003d1\\u0026_content_struts_action\\u003d%2Fext%2Fcontentlet%2Fedit_contentlet","type":{"type":"com.dotcms.contenttype.model.type.ImmutableWidgetContentType","data":{"multilingualable":false,"name":"Banner Carousel","id":"73061f34-7fa0-4f77-9724-5ca0013a0214","defaultType":false,"fixed":false,"iDate":1566406304000,"system":false,"versionable":true,"variable":"BannerCarousel","modDate":1585198548000,"host":"48190c8c-42c4-46af-8d1a-0cd5db894797","folder":"SYSTEM_FOLDER"}}}}	1585198551354	e64a5620-9bd4-4e08-a53a-67a80079eea1
a654828e-857a-4535-9da5-9a4f6f9b47bb	DELETE_BASE_CONTENT_TYPE	{"type":"com.dotcms.api.system.event.ContentTypePayloadDataWrapper","visibility":"PERMISSION","visibilityValue":"1","visibilityType":"java.lang.String","data":{"actionUrl":"/c/portal/layout?p_l_id\\u003d71b8a1ca-37b6-4b6e-a43b-c7482f28db6c\\u0026p_p_id\\u003dcontent\\u0026p_p_action\\u003d1\\u0026p_p_state\\u003dmaximized\\u0026_content_inode\\u003d\\u0026_content_referer\\u003d%2Fc%2Fportal%2Flayout%3Fp_l_id%3D71b8a1ca-37b6-4b6e-a43b-c7482f28db6c%26p_p_id%3Dcontent%26p_p_action%3D1%26p_p_state%3Dmaximized%26_content_inode%3D%26_content_structure_id%3D27e628b7-6e61-4397-92db-434e0edc92ad%26_content_cmd%3Dnew%26_content_lang%3D1%26_content_struts_action%3D%252Fext%252Fcontentlet%252Fview_contentlets\\u0026_content_selectedStructure\\u003d27e628b7-6e61-4397-92db-434e0edc92ad\\u0026_content_cmd\\u003dnew\\u0026_content_lang\\u003d1\\u0026_content_struts_action\\u003d%2Fext%2Fcontentlet%2Fedit_contentlet","type":{"type":"com.dotcms.contenttype.model.type.ImmutablePageContentType","data":{"name":"Landing Page","id":"27e628b7-6e61-4397-92db-434e0edc92ad","description":"Marketign Landing Page","defaultType":false,"fixed":false,"iDate":1569351494000,"system":false,"versionable":true,"multilingualable":false,"variable":"LandingPage","modDate":1585197308000,"host":"SYSTEM_HOST","folder":"SYSTEM_FOLDER"}}}}	1585198555097	e64a5620-9bd4-4e08-a53a-67a80079eea1
55c429db-73e2-44a8-a7ba-79bc60c1a3fc	DELETE_BASE_CONTENT_TYPE	{"type":"com.dotcms.api.system.event.ContentTypePayloadDataWrapper","visibility":"PERMISSION","visibilityValue":"1","visibilityType":"java.lang.String","data":{"actionUrl":"/c/portal/layout?p_l_id\\u003d71b8a1ca-37b6-4b6e-a43b-c7482f28db6c\\u0026p_p_id\\u003dcontent\\u0026p_p_action\\u003d1\\u0026p_p_state\\u003dmaximized\\u0026_content_inode\\u003d\\u0026_content_referer\\u003d%2Fc%2Fportal%2Flayout%3Fp_l_id%3D71b8a1ca-37b6-4b6e-a43b-c7482f28db6c%26p_p_id%3Dcontent%26p_p_action%3D1%26p_p_state%3Dmaximized%26_content_inode%3D%26_content_structure_id%3Dd5ea385d-32ee-4f35-8172-d37f58d9cd7a%26_content_cmd%3Dnew%26_content_lang%3D1%26_content_struts_action%3D%252Fext%252Fcontentlet%252Fview_contentlets\\u0026_content_selectedStructure\\u003dd5ea385d-32ee-4f35-8172-d37f58d9cd7a\\u0026_content_cmd\\u003dnew\\u0026_content_lang\\u003d1\\u0026_content_struts_action\\u003d%2Fext%2Fcontentlet%2Fedit_contentlet","type":{"type":"com.dotcms.contenttype.model.type.ImmutableFileAssetContentType","data":{"name":"Image","id":"d5ea385d-32ee-4f35-8172-d37f58d9cd7a","defaultType":false,"fixed":false,"iDate":1536951513000,"system":false,"versionable":true,"multilingualable":false,"variable":"Image","modDate":1585197307000,"host":"SYSTEM_HOST","folder":"SYSTEM_FOLDER"}}}}	1585198560944	e64a5620-9bd4-4e08-a53a-67a80079eea1
c869adc9-d066-4eba-8ee4-7085d3389f56	NOTIFICATION	{"type":"com.dotcms.notifications.bean.Notification","visibility":"USER","visibilityValue":"dotcms.org.1","visibilityType":"java.lang.String","data":{"groupId":"e361b942-dd5d-41ef-b64f-24bcfec5e33d","notificationData":{"title":{"key":""},"message":{"key":"Deletion of user user-ddb808e6-4f68-4f7a-96d0-81277a66953f/Will Ezell has been started. Replacement user: dotcms.org.2806/Bill Intranet."}},"level":"INFO","userId":"dotcms.org.1","timeSent":1585198595713,"wasRead":false,"prettyDate":"seconds ago"}}	1585198595713	e64a5620-9bd4-4e08-a53a-67a80079eea1
9cb0bcee-a0fb-4c3b-84e3-9b24b6051dbb	DELETE_BASE_CONTENT_TYPE	{"type":"com.dotcms.api.system.event.ContentTypePayloadDataWrapper","visibility":"PERMISSION","visibilityValue":"1","visibilityType":"java.lang.String","data":{"actionUrl":"/c/portal/layout?p_l_id\\u003d71b8a1ca-37b6-4b6e-a43b-c7482f28db6c\\u0026p_p_id\\u003dcontent\\u0026p_p_action\\u003d1\\u0026p_p_state\\u003dmaximized\\u0026_content_inode\\u003d\\u0026_content_referer\\u003d%2Fc%2Fportal%2Flayout%3Fp_l_id%3D71b8a1ca-37b6-4b6e-a43b-c7482f28db6c%26p_p_id%3Dcontent%26p_p_action%3D1%26p_p_state%3Dmaximized%26_content_inode%3D%26_content_structure_id%3D9e0a09af-a7be-4c83-9d5e-c6cc9c050219%26_content_cmd%3Dnew%26_content_lang%3D1%26_content_struts_action%3D%252Fext%252Fcontentlet%252Fview_contentlets\\u0026_content_selectedStructure\\u003d9e0a09af-a7be-4c83-9d5e-c6cc9c050219\\u0026_content_cmd\\u003dnew\\u0026_content_lang\\u003d1\\u0026_content_struts_action\\u003d%2Fext%2Fcontentlet%2Fedit_contentlet","type":{"type":"com.dotcms.contenttype.model.type.ImmutableWidgetContentType","data":{"multilingualable":false,"name":"VTL File","id":"9e0a09af-a7be-4c83-9d5e-c6cc9c050219","description":"Browse and include a vtl file to be parsed in your widget.","defaultType":false,"fixed":false,"iDate":1400083132822,"system":false,"versionable":true,"variable":"VtlInclude","modDate":1585197307000,"host":"SYSTEM_HOST","folder":"SYSTEM_FOLDER"}}}}	1585198564645	e64a5620-9bd4-4e08-a53a-67a80079eea1
f281a440-f2d5-4bef-bb4a-3f97a04e0e87	DELETE_BASE_CONTENT_TYPE	{"type":"com.dotcms.api.system.event.ContentTypePayloadDataWrapper","visibility":"PERMISSION","visibilityValue":"1","visibilityType":"java.lang.String","data":{"actionUrl":"/c/portal/layout?p_l_id\\u003d71b8a1ca-37b6-4b6e-a43b-c7482f28db6c\\u0026p_p_id\\u003dcontent\\u0026p_p_action\\u003d1\\u0026p_p_state\\u003dmaximized\\u0026_content_inode\\u003d\\u0026_content_referer\\u003d%2Fc%2Fportal%2Flayout%3Fp_l_id%3D71b8a1ca-37b6-4b6e-a43b-c7482f28db6c%26p_p_id%3Dcontent%26p_p_action%3D1%26p_p_state%3Dmaximized%26_content_inode%3D%26_content_structure_id%3D188f0f9f-5ffa-4835-8ef1-e729a19967de%26_content_cmd%3Dnew%26_content_lang%3D1%26_content_struts_action%3D%252Fext%252Fcontentlet%252Fview_contentlets\\u0026_content_selectedStructure\\u003d188f0f9f-5ffa-4835-8ef1-e729a19967de\\u0026_content_cmd\\u003dnew\\u0026_content_lang\\u003d1\\u0026_content_struts_action\\u003d%2Fext%2Fcontentlet%2Fedit_contentlet","type":{"type":"com.dotcms.contenttype.model.type.ImmutableSimpleContentType","data":{"name":"Video - Vimeo","id":"188f0f9f-5ffa-4835-8ef1-e729a19967de","defaultType":false,"fixed":false,"iDate":1564430765000,"system":false,"versionable":true,"multilingualable":false,"variable":"VideoVimeo","modDate":1585197305000,"host":"48190c8c-42c4-46af-8d1a-0cd5db894797","folder":"SYSTEM_FOLDER","requiredFields":[]}}}}	1585198570710	e64a5620-9bd4-4e08-a53a-67a80079eea1
97ec26f2-08db-41ad-a901-d8f1ea6c92e9	DELETE_BASE_CONTENT_TYPE	{"type":"com.dotcms.api.system.event.ContentTypePayloadDataWrapper","visibility":"PERMISSION","visibilityValue":"1","visibilityType":"java.lang.String","data":{"actionUrl":"/c/portal/layout?p_l_id\\u003d71b8a1ca-37b6-4b6e-a43b-c7482f28db6c\\u0026p_p_id\\u003dcontent\\u0026p_p_action\\u003d1\\u0026p_p_state\\u003dmaximized\\u0026_content_inode\\u003d\\u0026_content_referer\\u003d%2Fc%2Fportal%2Flayout%3Fp_l_id%3D71b8a1ca-37b6-4b6e-a43b-c7482f28db6c%26p_p_id%3Dcontent%26p_p_action%3D1%26p_p_state%3Dmaximized%26_content_inode%3D%26_content_structure_id%3D4b1fc848-87f0-4efb-94a8-d04e11f5d3fc%26_content_cmd%3Dnew%26_content_lang%3D1%26_content_struts_action%3D%252Fext%252Fcontentlet%252Fview_contentlets\\u0026_content_selectedStructure\\u003d4b1fc848-87f0-4efb-94a8-d04e11f5d3fc\\u0026_content_cmd\\u003dnew\\u0026_content_lang\\u003d1\\u0026_content_struts_action\\u003d%2Fext%2Fcontentlet%2Fedit_contentlet","type":{"type":"com.dotcms.contenttype.model.type.ImmutableWidgetContentType","data":{"multilingualable":false,"name":"Photo Gallery","id":"4b1fc848-87f0-4efb-94a8-d04e11f5d3fc","description":"Pulls a list of images based on folder","defaultType":false,"fixed":false,"iDate":1408051785158,"system":false,"versionable":true,"variable":"PhotoGallery","owner":"dotcms.org.1","modDate":1585197304000,"host":"48190c8c-42c4-46af-8d1a-0cd5db894797","folder":"SYSTEM_FOLDER"}}}}	1585198576172	e64a5620-9bd4-4e08-a53a-67a80079eea1
099e0fb7-498d-4862-b5db-7a7ad39eaf83	NOTIFICATION	{"type":"com.dotcms.notifications.bean.Notification","visibility":"USER","visibilityValue":"dotcms.org.1","visibilityType":"java.lang.String","data":{"groupId":"b674702b-1539-47b8-bec7-2099699a4ff5","notificationData":{"title":{"key":""},"message":{"key":"Deletion of user dotcms.org.2791/Steve Contributor has been started. Replacement user: dotcms.org.2806/Bill Intranet."}},"level":"INFO","userId":"dotcms.org.1","timeSent":1585198610273,"wasRead":false,"prettyDate":"seconds ago"}}	1585198610273	e64a5620-9bd4-4e08-a53a-67a80079eea1
d5845494-01f6-4ead-8c7d-3c06dddb34c9	NOTIFICATION	{"type":"com.dotcms.notifications.bean.Notification","visibility":"USER","visibilityValue":"dotcms.org.1","visibilityType":"java.lang.String","data":{"groupId":"3f25a071-7ad4-4e18-80a1-86323624b7fd","notificationData":{"title":{"key":""},"message":{"key":"Deletion of user dotcms.org.2909/John Editor has been started. Replacement user: dotcms.org.2806/Bill Intranet."}},"level":"INFO","userId":"dotcms.org.1","timeSent":1585198662110,"wasRead":false,"prettyDate":"seconds ago"}}	1585198662110	e64a5620-9bd4-4e08-a53a-67a80079eea1
1472dfc2-7c1d-4369-b4ee-98eb4e6278d0	NOTIFICATION	{"type":"com.dotcms.notifications.bean.Notification","visibility":"USER","visibilityValue":"dotcms.org.1","visibilityType":"java.lang.String","data":{"groupId":"cbffd0f9-7594-481e-b79e-d63453edae1d","notificationData":{"title":{"key":""},"message":{"key":"Deletion of user dotcms.org.2789/Joe Contributor has been started. Replacement user: dotcms.org.2806/Bill Intranet."}},"level":"INFO","userId":"dotcms.org.1","timeSent":1585198678942,"wasRead":false,"prettyDate":"seconds ago"}}	1585198678942	e64a5620-9bd4-4e08-a53a-67a80079eea1
4c4758bd-7c64-4b53-a9c6-55c14f7cb547	NOTIFICATION	{"type":"com.dotcms.notifications.bean.Notification","visibility":"USER","visibilityValue":"dotcms.org.1","visibilityType":"java.lang.String","data":{"groupId":"02dea71e-e980-43e4-b984-f8697f46624c","notificationData":{"title":{"key":""},"message":{"key":"User dotcms.org.2789/Joe Contributor was successfully deleted. Updated contents are being re-indexed."}},"level":"INFO","userId":"dotcms.org.1","timeSent":1585198678980,"wasRead":false,"prettyDate":"seconds ago"}}	1585198678980	e64a5620-9bd4-4e08-a53a-67a80079eea1
3b686cee-6512-4317-956a-600d3e46c3da	NOTIFICATION	{"type":"com.dotcms.notifications.bean.Notification","visibility":"USER","visibilityValue":"dotcms.org.1","visibilityType":"java.lang.String","data":{"groupId":"a34f442c-bf9d-4f4e-be99-6d02941626ba","notificationData":{"title":{"key":""},"message":{"key":"User dotcms.org.2802/Dave Smith was successfully deleted. Updated contents are being re-indexed."}},"level":"INFO","userId":"dotcms.org.1","timeSent":1585198721181,"wasRead":false,"prettyDate":"seconds ago"}}	1585198721181	e64a5620-9bd4-4e08-a53a-67a80079eea1
e8d134f3-8a8d-4f69-ad28-aa7559bbdb4c	NOTIFICATION	{"type":"com.dotcms.notifications.bean.Notification","visibility":"USER","visibilityValue":"dotcms.org.1","visibilityType":"java.lang.String","data":{"groupId":"d31b6b67-6b79-4528-bea2-2df877cf818b","notificationData":{"title":{"key":""},"message":{"key":"User dotcms.org.2795/Chris Publisher was successfully deleted. Updated contents are being re-indexed."}},"level":"INFO","userId":"dotcms.org.1","timeSent":1585198745987,"wasRead":false,"prettyDate":"seconds ago"}}	1585198745987	e64a5620-9bd4-4e08-a53a-67a80079eea1
ded58a7c-e581-43f4-b822-7f7e0b900858	DELETE_BASE_CONTENT_TYPE	{"type":"com.dotcms.api.system.event.ContentTypePayloadDataWrapper","visibility":"PERMISSION","visibilityValue":"1","visibilityType":"java.lang.String","data":{"actionUrl":"/c/portal/layout?p_l_id\\u003d71b8a1ca-37b6-4b6e-a43b-c7482f28db6c\\u0026p_p_id\\u003dcontent\\u0026p_p_action\\u003d1\\u0026p_p_state\\u003dmaximized\\u0026_content_inode\\u003d\\u0026_content_referer\\u003d%2Fc%2Fportal%2Flayout%3Fp_l_id%3D71b8a1ca-37b6-4b6e-a43b-c7482f28db6c%26p_p_id%3Dcontent%26p_p_action%3D1%26p_p_state%3Dmaximized%26_content_inode%3D%26_content_structure_id%3D9d8cba31-0072-4c38-96db-8b619f2b57ab%26_content_cmd%3Dnew%26_content_lang%3D1%26_content_struts_action%3D%252Fext%252Fcontentlet%252Fview_contentlets\\u0026_content_selectedStructure\\u003d9d8cba31-0072-4c38-96db-8b619f2b57ab\\u0026_content_cmd\\u003dnew\\u0026_content_lang\\u003d1\\u0026_content_struts_action\\u003d%2Fext%2Fcontentlet%2Fedit_contentlet","type":{"type":"com.dotcms.contenttype.model.type.ImmutableWidgetContentType","data":{"multilingualable":false,"name":"Code Snippet ","id":"9d8cba31-0072-4c38-96db-8b619f2b57ab","description":"Use this as your default velocity container","defaultType":false,"fixed":false,"iDate":1309185036393,"system":false,"versionable":true,"variable":"SimpleWidget","modDate":1585197307000,"host":"SYSTEM_HOST","folder":"SYSTEM_FOLDER"}}}}	1585198567174	e64a5620-9bd4-4e08-a53a-67a80079eea1
3220d7ab-c01d-4088-85cd-8641538aeba7	DELETE_BASE_CONTENT_TYPE	{"type":"com.dotcms.api.system.event.ContentTypePayloadDataWrapper","visibility":"PERMISSION","visibilityValue":"1","visibilityType":"java.lang.String","data":{"actionUrl":"/c/portal/layout?p_l_id\\u003d71b8a1ca-37b6-4b6e-a43b-c7482f28db6c\\u0026p_p_id\\u003dcontent\\u0026p_p_action\\u003d1\\u0026p_p_state\\u003dmaximized\\u0026_content_inode\\u003d\\u0026_content_referer\\u003d%2Fc%2Fportal%2Flayout%3Fp_l_id%3D71b8a1ca-37b6-4b6e-a43b-c7482f28db6c%26p_p_id%3Dcontent%26p_p_action%3D1%26p_p_state%3Dmaximized%26_content_inode%3D%26_content_structure_id%3De65543eb-6b81-42e0-a59b-1bb9fd7bfce4%26_content_cmd%3Dnew%26_content_lang%3D1%26_content_struts_action%3D%252Fext%252Fcontentlet%252Fview_contentlets\\u0026_content_selectedStructure\\u003de65543eb-6b81-42e0-a59b-1bb9fd7bfce4\\u0026_content_cmd\\u003dnew\\u0026_content_lang\\u003d1\\u0026_content_struts_action\\u003d%2Fext%2Fcontentlet%2Fedit_contentlet","type":{"type":"com.dotcms.contenttype.model.type.ImmutableSimpleContentType","data":{"name":"Video - YouTube","id":"e65543eb-6b81-42e0-a59b-1bb9fd7bfce4","description":"YouTube Video","defaultType":false,"detailPage":"c308f4bb-77d0-4735-a84b-21d7af8d2604","fixed":false,"iDate":1541099140000,"system":false,"versionable":true,"multilingualable":false,"variable":"Video","urlMapPattern":"/video/{urlTitle}","modDate":1585197305000,"host":"48190c8c-42c4-46af-8d1a-0cd5db894797","folder":"SYSTEM_FOLDER","requiredFields":[]}}}}	1585198573679	e64a5620-9bd4-4e08-a53a-67a80079eea1
1effca66-0c3c-4317-a2e8-8a5e4a6e25ae	NOTIFICATION	{"type":"com.dotcms.notifications.bean.Notification","visibility":"USER","visibilityValue":"dotcms.org.1","visibilityType":"java.lang.String","data":{"groupId":"8d4c5353-9f94-405c-a97b-54b39c1a4dbd","notificationData":{"title":{"key":""},"message":{"key":"User user-ddb808e6-4f68-4f7a-96d0-81277a66953f/Will Ezell was successfully deleted. Updated contents are being re-indexed."}},"level":"INFO","userId":"dotcms.org.1","timeSent":1585198595881,"wasRead":false,"prettyDate":"seconds ago"}}	1585198595881	e64a5620-9bd4-4e08-a53a-67a80079eea1
637c9542-8075-4d84-af07-ccabf4b4400f	NOTIFICATION	{"type":"com.dotcms.notifications.bean.Notification","visibility":"USER","visibilityValue":"dotcms.org.1","visibilityType":"java.lang.String","data":{"groupId":"2055104e-3b7f-4b5c-abec-97db48a9cda6","notificationData":{"title":{"key":""},"message":{"key":"Deletion of user dotcms.org.2798/Nick Reviewer has been started. Replacement user: dotcms.org.2806/Bill Intranet."}},"level":"INFO","userId":"dotcms.org.1","timeSent":1585198650010,"wasRead":false,"prettyDate":"seconds ago"}}	1585198650010	e64a5620-9bd4-4e08-a53a-67a80079eea1
0ee5a5e1-1218-4485-a597-57eb3c37006e	NOTIFICATION	{"type":"com.dotcms.notifications.bean.Notification","visibility":"USER","visibilityValue":"dotcms.org.1","visibilityType":"java.lang.String","data":{"groupId":"56b97cae-934e-4201-a62a-7928665c2806","notificationData":{"title":{"key":""},"message":{"key":"User dotcms.org.2909/John Editor was successfully deleted. Updated contents are being re-indexed."}},"level":"INFO","userId":"dotcms.org.1","timeSent":1585198662144,"wasRead":false,"prettyDate":"seconds ago"}}	1585198662144	e64a5620-9bd4-4e08-a53a-67a80079eea1
c235cef6-f57d-40df-87af-910ac5e685ac	NOTIFICATION	{"type":"com.dotcms.notifications.bean.Notification","visibility":"USER","visibilityValue":"dotcms.org.1","visibilityType":"java.lang.String","data":{"groupId":"3bed2032-e808-4aeb-b7b2-6b93c733d5e4","notificationData":{"title":{"key":""},"message":{"key":"Deletion of user dotcms.org.2787/Jane Reviewer has been started. Replacement user: dotcms.org.2806/Bill Intranet."}},"level":"INFO","userId":"dotcms.org.1","timeSent":1585198702653,"wasRead":false,"prettyDate":"seconds ago"}}	1585198702653	e64a5620-9bd4-4e08-a53a-67a80079eea1
08b2cda7-6c82-4adf-a1e0-09b28be9daff	NOTIFICATION	{"type":"com.dotcms.notifications.bean.Notification","visibility":"USER","visibilityValue":"dotcms.org.1","visibilityType":"java.lang.String","data":{"groupId":"f6f66cc4-43d1-46d3-ac72-e1d69d15ba08","notificationData":{"title":{"key":""},"message":{"key":"Deletion of user dotcms.org.2802/Dave Smith has been started. Replacement user: dotcms.org.2806/Bill Intranet."}},"level":"INFO","userId":"dotcms.org.1","timeSent":1585198721151,"wasRead":false,"prettyDate":"seconds ago"}}	1585198721151	e64a5620-9bd4-4e08-a53a-67a80079eea1
81ec292b-952b-4118-bc63-355d85ac7c28	NOTIFICATION	{"type":"com.dotcms.notifications.bean.Notification","visibility":"USER","visibilityValue":"dotcms.org.1","visibilityType":"java.lang.String","data":{"groupId":"dfa92d3f-b574-42b5-8166-e6e374b6f789","notificationData":{"title":{"key":""},"message":{"key":"User dotcms.org.2806/Bill Intranet was successfully deleted. Updated contents are being re-indexed."}},"level":"INFO","userId":"dotcms.org.1","timeSent":1585198791067,"wasRead":false,"prettyDate":"seconds ago"}}	1585198791067	e64a5620-9bd4-4e08-a53a-67a80079eea1
6954769b-4bdf-4ce9-9de6-06772d50ae0c	NOTIFICATION	{"type":"com.dotcms.notifications.bean.Notification","visibility":"USER","visibilityValue":"dotcms.org.1","visibilityType":"java.lang.String","data":{"groupId":"0368885c-681e-49d5-b6e4-0fffa649d174","notificationData":{"title":{"key":""},"message":{"key":"Deletion of user 036fd43a-6d98-46e0-b22e-bae02cb86f0c/Jason Smith has been started. Replacement user: 036fd43a-6d98-46e0-b22e-bae02cb86f0c/Jason Smith."}},"level":"INFO","userId":"dotcms.org.1","timeSent":1585198833017,"wasRead":false,"prettyDate":"seconds ago"}}	1585198833017	e64a5620-9bd4-4e08-a53a-67a80079eea1
3b94a406-4026-43bc-b880-32454a4a7e3f	NOTIFICATION	{"type":"com.dotcms.notifications.bean.Notification","visibility":"USER","visibilityValue":"dotcms.org.1","visibilityType":"java.lang.String","data":{"groupId":"b1af5727-d0dc-48e5-83fd-03ac98232628","notificationData":{"title":{"key":""},"message":{"key":"Deletion of user 036fd43a-6d98-46e0-b22e-bae02cb86f0c/Jason Smith has been started. Replacement user: dotcms.org.2808/Admin2 User."}},"level":"INFO","userId":"dotcms.org.1","timeSent":1585198848145,"wasRead":false,"prettyDate":"seconds ago"}}	1585198848145	e64a5620-9bd4-4e08-a53a-67a80079eea1
95ac36a0-eb1c-4521-b94a-3df7e98aed1e	NOTIFICATION	{"type":"com.dotcms.notifications.bean.Notification","visibility":"USER","visibilityValue":"dotcms.org.1","visibilityType":"java.lang.String","data":{"groupId":"cd2874cd-1223-4c65-86f3-ae40c5be7770","notificationData":{"title":{"key":""},"message":{"key":"User dotcms.org.2791/Steve Contributor was successfully deleted. Updated contents are being re-indexed."}},"level":"INFO","userId":"dotcms.org.1","timeSent":1585198610311,"wasRead":false,"prettyDate":"seconds ago"}}	1585198610311	e64a5620-9bd4-4e08-a53a-67a80079eea1
11c31086-d067-4ae9-853d-1a201b88e5db	NOTIFICATION	{"type":"com.dotcms.notifications.bean.Notification","visibility":"USER","visibilityValue":"dotcms.org.1","visibilityType":"java.lang.String","data":{"groupId":"859da1bc-2938-4ba5-91a6-1dffb621b511","notificationData":{"title":{"key":""},"message":{"key":"User 9522e2cb-8ff2-45b2-b4f6-f1cc7252d83c/Sandra Gonzalez was successfully deleted. Updated contents are being re-indexed."}},"level":"INFO","userId":"dotcms.org.1","timeSent":1585198626318,"wasRead":false,"prettyDate":"seconds ago"}}	1585198626318	e64a5620-9bd4-4e08-a53a-67a80079eea1
6139b677-731f-49c9-b216-a0f4f9430728	NOTIFICATION	{"type":"com.dotcms.notifications.bean.Notification","visibility":"USER","visibilityValue":"dotcms.org.1","visibilityType":"java.lang.String","data":{"groupId":"f0225d3e-2307-4431-a7fe-187f038c168b","notificationData":{"title":{"key":""},"message":{"key":"User dotcms.org.2811/John Doe was successfully deleted. Updated contents are being re-indexed."}},"level":"INFO","userId":"dotcms.org.1","timeSent":1585198671302,"wasRead":false,"prettyDate":"seconds ago"}}	1585198671302	e64a5620-9bd4-4e08-a53a-67a80079eea1
4e4bd716-34fa-4a75-9269-13aad366018a	NOTIFICATION	{"type":"com.dotcms.notifications.bean.Notification","visibility":"USER","visibilityValue":"dotcms.org.1","visibilityType":"java.lang.String","data":{"groupId":"ce975858-a0d5-4808-8359-d4c1a8a9e665","notificationData":{"title":{"key":""},"message":{"key":"User dotcms.org.2787/Jane Reviewer was successfully deleted. Updated contents are being re-indexed."}},"level":"INFO","userId":"dotcms.org.1","timeSent":1585198702684,"wasRead":false,"prettyDate":"seconds ago"}}	1585198702684	e64a5620-9bd4-4e08-a53a-67a80079eea1
16af112b-e317-4af2-9efd-affba15cafaf	NOTIFICATION	{"type":"com.dotcms.notifications.bean.Notification","visibility":"USER","visibilityValue":"dotcms.org.1","visibilityType":"java.lang.String","data":{"groupId":"f2ba7523-8035-4c25-bd15-33f5500d9e46","notificationData":{"title":{"key":""},"message":{"key":"Deletion of user dotcms.org.2908/Bloggy Smith has been started. Replacement user: dotcms.org.2806/Bill Intranet."}},"level":"INFO","userId":"dotcms.org.1","timeSent":1585198756846,"wasRead":false,"prettyDate":"seconds ago"}}	1585198756846	e64a5620-9bd4-4e08-a53a-67a80079eea1
47f705e7-ea50-4f32-b58f-f12b79b8bc0d	NOTIFICATION	{"type":"com.dotcms.notifications.bean.Notification","visibility":"USER","visibilityValue":"dotcms.org.1","visibilityType":"java.lang.String","data":{"groupId":"273dbf35-7b75-42e0-850d-d1d0cc50b2bc","notificationData":{"title":{"key":""},"message":{"key":"Unable to delete user 036fd43a-6d98-46e0-b22e-bae02cb86f0c/Jason Smith."}},"level":"ERROR","userId":"dotcms.org.1","timeSent":1585198848172,"wasRead":false,"prettyDate":"seconds ago"}}	1585198848172	e64a5620-9bd4-4e08-a53a-67a80079eea1
4eea091c-c010-4de3-8122-07e6552315be	NOTIFICATION	{"type":"com.dotcms.notifications.bean.Notification","visibility":"USER","visibilityValue":"dotcms.org.1","visibilityType":"java.lang.String","data":{"groupId":"46bbb87d-9994-452d-862e-d98203b31d5c","notificationData":{"title":{"key":""},"message":{"key":"Deletion of user 9522e2cb-8ff2-45b2-b4f6-f1cc7252d83c/Sandra Gonzalez has been started. Replacement user: dotcms.org.2806/Bill Intranet."}},"level":"INFO","userId":"dotcms.org.1","timeSent":1585198626292,"wasRead":false,"prettyDate":"seconds ago"}}	1585198626292	e64a5620-9bd4-4e08-a53a-67a80079eea1
08822ded-4f78-4282-ad8a-5d4130ef6543	NOTIFICATION	{"type":"com.dotcms.notifications.bean.Notification","visibility":"USER","visibilityValue":"dotcms.org.1","visibilityType":"java.lang.String","data":{"groupId":"2ae76356-ddcf-4938-91ed-ec71e7e42277","notificationData":{"title":{"key":""},"message":{"key":"Deletion of user user-b1b27655-44bb-4f81-8688-a8763005a377/Samanta Ledezma has been started. Replacement user: dotcms.org.2806/Bill Intranet."}},"level":"INFO","userId":"dotcms.org.1","timeSent":1585198639736,"wasRead":false,"prettyDate":"seconds ago"}}	1585198639736	e64a5620-9bd4-4e08-a53a-67a80079eea1
c27030d9-42bf-4fe8-ba06-7806a23abed6	NOTIFICATION	{"type":"com.dotcms.notifications.bean.Notification","visibility":"USER","visibilityValue":"dotcms.org.1","visibilityType":"java.lang.String","data":{"groupId":"e2d415ba-f200-4699-b7c0-38c9244d958d","notificationData":{"title":{"key":""},"message":{"key":"User user-b1b27655-44bb-4f81-8688-a8763005a377/Samanta Ledezma was successfully deleted. Updated contents are being re-indexed."}},"level":"INFO","userId":"dotcms.org.1","timeSent":1585198639769,"wasRead":false,"prettyDate":"seconds ago"}}	1585198639769	e64a5620-9bd4-4e08-a53a-67a80079eea1
8bc1f8b4-3e39-499f-a097-6b4fe1e73ddf	NOTIFICATION	{"type":"com.dotcms.notifications.bean.Notification","visibility":"USER","visibilityValue":"dotcms.org.1","visibilityType":"java.lang.String","data":{"groupId":"2b45e6df-7cbe-406b-bb95-8f2d7092587b","notificationData":{"title":{"key":""},"message":{"key":"User dotcms.org.2798/Nick Reviewer was successfully deleted. Updated contents are being re-indexed."}},"level":"INFO","userId":"dotcms.org.1","timeSent":1585198650038,"wasRead":false,"prettyDate":"seconds ago"}}	1585198650038	e64a5620-9bd4-4e08-a53a-67a80079eea1
0f0686c8-bdb2-45ea-a5d5-e31a3bfe11ac	NOTIFICATION	{"type":"com.dotcms.notifications.bean.Notification","visibility":"USER","visibilityValue":"dotcms.org.1","visibilityType":"java.lang.String","data":{"groupId":"8e7a2159-d93b-4152-94e0-12270d848ead","notificationData":{"title":{"key":""},"message":{"key":"Deletion of user dotcms.org.2811/John Doe has been started. Replacement user: dotcms.org.2806/Bill Intranet."}},"level":"INFO","userId":"dotcms.org.1","timeSent":1585198671275,"wasRead":false,"prettyDate":"seconds ago"}}	1585198671275	e64a5620-9bd4-4e08-a53a-67a80079eea1
caad2bfa-e7f5-41aa-998b-ff0648ca1429	NOTIFICATION	{"type":"com.dotcms.notifications.bean.Notification","visibility":"USER","visibilityValue":"dotcms.org.1","visibilityType":"java.lang.String","data":{"groupId":"c85c29cd-fb45-4c38-b705-10174b0a8b73","notificationData":{"title":{"key":""},"message":{"key":"Deletion of user 036fd43a-6d98-46e0-b22e-bae02cb86f0c/Jason Smith has been started. Replacement user: dotcms.org.2806/Bill Intranet."}},"level":"INFO","userId":"dotcms.org.1","timeSent":1585198687407,"wasRead":false,"prettyDate":"seconds ago"}}	1585198687407	e64a5620-9bd4-4e08-a53a-67a80079eea1
14426b1e-0b76-4ca5-a277-358b8d8370fa	NOTIFICATION	{"type":"com.dotcms.notifications.bean.Notification","visibility":"USER","visibilityValue":"dotcms.org.1","visibilityType":"java.lang.String","data":{"groupId":"df195876-891a-4c27-9633-50c7414280df","notificationData":{"title":{"key":""},"message":{"key":"Unable to delete user 036fd43a-6d98-46e0-b22e-bae02cb86f0c/Jason Smith."}},"level":"ERROR","userId":"dotcms.org.1","timeSent":1585198687506,"wasRead":false,"prettyDate":"seconds ago"}}	1585198687506	e64a5620-9bd4-4e08-a53a-67a80079eea1
08947c94-a0aa-441a-a61e-b182ff7acd5c	NOTIFICATION	{"type":"com.dotcms.notifications.bean.Notification","visibility":"USER","visibilityValue":"dotcms.org.1","visibilityType":"java.lang.String","data":{"groupId":"a663c293-dab9-486c-8cc1-d3eecbf690fb","notificationData":{"title":{"key":""},"message":{"key":"Deletion of user 86fe5be1-4624-4595-bf2d-af8d559414b1/Dean Gonzalez has been started. Replacement user: dotcms.org.2806/Bill Intranet."}},"level":"INFO","userId":"dotcms.org.1","timeSent":1585198712444,"wasRead":false,"prettyDate":"seconds ago"}}	1585198712444	e64a5620-9bd4-4e08-a53a-67a80079eea1
ad9e40ee-f866-42c9-a0eb-bf6ef0928d14	NOTIFICATION	{"type":"com.dotcms.notifications.bean.Notification","visibility":"USER","visibilityValue":"dotcms.org.1","visibilityType":"java.lang.String","data":{"groupId":"4cbcdfd1-b73e-4871-88a8-fd261eddd82e","notificationData":{"title":{"key":""},"message":{"key":"User 86fe5be1-4624-4595-bf2d-af8d559414b1/Dean Gonzalez was successfully deleted. Updated contents are being re-indexed."}},"level":"INFO","userId":"dotcms.org.1","timeSent":1585198712475,"wasRead":false,"prettyDate":"seconds ago"}}	1585198712475	e64a5620-9bd4-4e08-a53a-67a80079eea1
87d419f1-9b8d-47d4-b0bb-844f75b7df66	NOTIFICATION	{"type":"com.dotcms.notifications.bean.Notification","visibility":"USER","visibilityValue":"dotcms.org.1","visibilityType":"java.lang.String","data":{"groupId":"1e1d1a50-39c5-4a8b-974e-97ffe8a78cab","notificationData":{"title":{"key":""},"message":{"key":"Deletion of user dotcms.org.2793/Daniel Publisher has been started. Replacement user: dotcms.org.2806/Bill Intranet."}},"level":"INFO","userId":"dotcms.org.1","timeSent":1585198731854,"wasRead":false,"prettyDate":"seconds ago"}}	1585198731854	e64a5620-9bd4-4e08-a53a-67a80079eea1
abdf5218-1f87-41df-bae2-0b5ac3d74e86	NOTIFICATION	{"type":"com.dotcms.notifications.bean.Notification","visibility":"USER","visibilityValue":"dotcms.org.1","visibilityType":"java.lang.String","data":{"groupId":"511bb705-cc44-47f9-8663-e40cc9fffdcf","notificationData":{"title":{"key":""},"message":{"key":"User dotcms.org.2793/Daniel Publisher was successfully deleted. Updated contents are being re-indexed."}},"level":"INFO","userId":"dotcms.org.1","timeSent":1585198731882,"wasRead":false,"prettyDate":"seconds ago"}}	1585198731882	e64a5620-9bd4-4e08-a53a-67a80079eea1
aaa3e125-7fd1-4a5a-9a53-427cea1453c3	NOTIFICATION	{"type":"com.dotcms.notifications.bean.Notification","visibility":"USER","visibilityValue":"dotcms.org.1","visibilityType":"java.lang.String","data":{"groupId":"5df327a9-cdcb-4b3d-9bab-1a5e9101a889","notificationData":{"title":{"key":""},"message":{"key":"Deletion of user dotcms.org.2795/Chris Publisher has been started. Replacement user: dotcms.org.2806/Bill Intranet."}},"level":"INFO","userId":"dotcms.org.1","timeSent":1585198745958,"wasRead":false,"prettyDate":"seconds ago"}}	1585198745958	e64a5620-9bd4-4e08-a53a-67a80079eea1
7cf1e4ba-1f29-4df6-abda-22497bab0684	NOTIFICATION	{"type":"com.dotcms.notifications.bean.Notification","visibility":"USER","visibilityValue":"dotcms.org.1","visibilityType":"java.lang.String","data":{"groupId":"b18609ae-adae-4f83-b94a-2c2b8f33a53b","notificationData":{"title":{"key":""},"message":{"key":"Deletion of user 036fd43a-6d98-46e0-b22e-bae02cb86f0c/Jason Smith has been started. Replacement user: dotcms.org.2806/Bill Intranet."}},"level":"INFO","userId":"dotcms.org.1","timeSent":1585198769445,"wasRead":false,"prettyDate":"seconds ago"}}	1585198769445	e64a5620-9bd4-4e08-a53a-67a80079eea1
001b84af-0e34-4b68-bec1-9fe25db6c11e	NOTIFICATION	{"type":"com.dotcms.notifications.bean.Notification","visibility":"USER","visibilityValue":"dotcms.org.1","visibilityType":"java.lang.String","data":{"groupId":"d1735707-c7ef-4a6e-813a-08aaede1e88b","notificationData":{"title":{"key":""},"message":{"key":"User dotcms.org.2908/Bloggy Smith was successfully deleted. Updated contents are being re-indexed."}},"level":"INFO","userId":"dotcms.org.1","timeSent":1585198756875,"wasRead":false,"prettyDate":"seconds ago"}}	1585198756875	e64a5620-9bd4-4e08-a53a-67a80079eea1
be93e86e-b189-4c67-a802-5017c4986d46	NOTIFICATION	{"type":"com.dotcms.notifications.bean.Notification","visibility":"USER","visibilityValue":"dotcms.org.1","visibilityType":"java.lang.String","data":{"groupId":"8656d339-472b-4a2d-8109-8f015456da57","notificationData":{"title":{"key":""},"message":{"key":"Deletion of user dotcms.org.2806/Bill Intranet has been started. Replacement user: dotcms.org.2808/Admin2 User."}},"level":"INFO","userId":"dotcms.org.1","timeSent":1585198791033,"wasRead":false,"prettyDate":"seconds ago"}}	1585198791033	e64a5620-9bd4-4e08-a53a-67a80079eea1
67db4c04-de06-4ba9-a649-386f86f53d4f	NOTIFICATION	{"type":"com.dotcms.notifications.bean.Notification","visibility":"USER","visibilityValue":"dotcms.org.1","visibilityType":"java.lang.String","data":{"groupId":"9483ba2c-11b0-4643-8d83-4f3c9cc28449","notificationData":{"title":{"key":""},"message":{"key":"Unable to delete user 036fd43a-6d98-46e0-b22e-bae02cb86f0c/Jason Smith."}},"level":"ERROR","userId":"dotcms.org.1","timeSent":1585198769465,"wasRead":false,"prettyDate":"seconds ago"}}	1585198769465	e64a5620-9bd4-4e08-a53a-67a80079eea1
61cf6151-652a-4110-b9ec-6bd93b43a12f	NOTIFICATION	{"type":"com.dotcms.notifications.bean.Notification","visibility":"USER","visibilityValue":"dotcms.org.1","visibilityType":"java.lang.String","data":{"groupId":"55139c18-8803-462b-ab14-3d0d8171ff97","notificationData":{"title":{"key":""},"message":{"key":"Unable to delete user 036fd43a-6d98-46e0-b22e-bae02cb86f0c/Jason Smith."}},"level":"ERROR","userId":"dotcms.org.1","timeSent":1585198833026,"wasRead":false,"prettyDate":"seconds ago"}}	1585198833026	e64a5620-9bd4-4e08-a53a-67a80079eea1
86b126a9-9ec1-4052-a81e-8656d26c190e	NOTIFICATION	{"type":"com.dotcms.notifications.bean.Notification","visibility":"ROLE","visibilityValue":"892ab105-f212-407f-8fb4-58ec59310a5e","visibilityType":"java.lang.String","data":{"groupId":"50a5c0e2-d8ee-412d-a6c5-cd4e9f4d03ca","notificationData":{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}},"level":"INFO","userId":"system","timeSent":1585199190080,"wasRead":false,"prettyDate":"seconds ago"}}	1585199190080	e64a5620-9bd4-4e08-a53a-67a80079eea1
1572e04a-c36b-4235-81f9-9086049180de	NOTIFICATION	{"type":"com.dotcms.notifications.bean.Notification","visibility":"ROLE","visibilityValue":"892ab105-f212-407f-8fb4-58ec59310a5e","visibilityType":"java.lang.String","data":{"groupId":"749adecf-7882-4fe0-b60c-cfe1e4670d2c","notificationData":{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}},"level":"INFO","userId":"system","timeSent":1585199193582,"wasRead":false,"prettyDate":"seconds ago"}}	1585199193582	e64a5620-9bd4-4e08-a53a-67a80079eea1
88596b7b-6c62-4d64-ad30-20fbe7eb9caa	NOTIFICATION	{"type":"com.dotcms.notifications.bean.Notification","visibility":"ROLE","visibilityValue":"892ab105-f212-407f-8fb4-58ec59310a5e","visibilityType":"java.lang.String","data":{"groupId":"8f47ce63-83b6-4b42-925c-d4cfb41b858c","notificationData":{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}},"level":"INFO","userId":"system","timeSent":1585199197084,"wasRead":false,"prettyDate":"seconds ago"}}	1585199197084	e64a5620-9bd4-4e08-a53a-67a80079eea1
d0d91b10-b66b-47e2-a5f3-dc71cf7b0829	NOTIFICATION	{"type":"com.dotcms.notifications.bean.Notification","visibility":"ROLE","visibilityValue":"892ab105-f212-407f-8fb4-58ec59310a5e","visibilityType":"java.lang.String","data":{"groupId":"249ad4c9-038c-4b93-ac47-f5a2d3a37d38","notificationData":{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}},"level":"INFO","userId":"system","timeSent":1585199200585,"wasRead":false,"prettyDate":"seconds ago"}}	1585199200585	e64a5620-9bd4-4e08-a53a-67a80079eea1
6857f3c2-a623-486b-9631-25ce69aea2d5	NOTIFICATION	{"type":"com.dotcms.notifications.bean.Notification","visibility":"ROLE","visibilityValue":"892ab105-f212-407f-8fb4-58ec59310a5e","visibilityType":"java.lang.String","data":{"groupId":"8a848cd9-c261-4ae6-bcee-58c018cd0492","notificationData":{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}},"level":"INFO","userId":"system","timeSent":1585199201096,"wasRead":false,"prettyDate":"seconds ago"}}	1585199201096	e64a5620-9bd4-4e08-a53a-67a80079eea1
9093e944-3c8f-4689-ab56-270c57594ff2	SWITCH_SITE	{"type":"com.dotmarketing.beans.Host","visibility":"USER_SESSION","visibilityValue":{"user":"dotcms.org.1","sessionId":"26E1A46BAD0D767D525925FE423703DB"},"visibilityType":"com.dotcms.api.system.event.UserSessionBean","data":{"hostName":"demo.dotcms.com","googleMap":"AIzaSyDXvD7JA5Q8S5VgfviI8nDinAq9x5Utmu0","modDate":1580831056732,"aliases":"test.dotcms.com\\ntest2.dotcms.com\\nlocalhost\\n127.0.0.1","keywords":"CMS, Web Content Management, Open Source, Java, J2EE, DXP, NoCode, OSGI, Apache Velocity, Elasticsearch, RESTful Services, REST API, Workflows, Personalization, Multilingual, I18N, L10N, Internationalization, Localization, Docker CMS, Containerized CMS","description":"dotCMS starter site was designed to demonstrate what you can do with dotCMS.","type":"host","title":"demo.dotcms.com","proxyEditModeUrl":"https://ematest.dotcms.com:8443","inode":"0c3418eb-4c27-4d71-937d-bf231399312a","hostname":"demo.dotcms.com","__DOTNAME__":"demo.dotcms.com","addThis":"ra-4e02119211875e7b","disabledWYSIWYG":[],"host":"SYSTEM_HOST","lastReview":1580831056724,"stInode":"855a2d72-f2f3-4169-8b04-ac5157c4380c","owner":"dotcms.org.1","nullProperties":["embeddedDashboard","wfExpireDate","wfPublishDate","wfNeverExpire","wfActionAssign","wfActionId","wfPublishTime","wfActionComments","wfExpireTime"],"identifier":"48190c8c-42c4-46af-8d1a-0cd5db894797","runDashboard":false,"languageId":1,"titleImage":"TITLE_IMAGE_NOT_FOUND","isDefault":true,"folder":"SYSTEM_FOLDER","googleAnalytics":"UA-9877660-3","tagStorage":"SYSTEM_HOST","isSystemHost":false,"sortOrder":0,"modUser":"dotcms.org.1","lowIndexPriority":false,"archived":false}}	1585198912019	e64a5620-9bd4-4e08-a53a-67a80079eea1
ffef7f95-f788-4fa8-a78e-207ccaae691c	SESSION_DESTROYED	{"type":"java.lang.Long","visibility":"USER_SESSION","visibilityValue":{"user":"dotcms.org.1","sessionId":"26E1A46BAD0D767D525925FE423703DB"},"visibilityType":"com.dotcms.api.system.event.UserSessionBean","data":1585198912021}	1585198912021	e64a5620-9bd4-4e08-a53a-67a80079eea1
892e51ff-7734-4e23-a209-0ddd2b707b2d	SWITCH_SITE	{"type":"com.dotmarketing.beans.Host","visibility":"USER_SESSION","visibilityValue":{"user":"dotcms.org.1","sessionId":"F1E296F17C64A201F487A0E82A4F2ABB"},"visibilityType":"com.dotcms.api.system.event.UserSessionBean","data":{"hostName":"demo.dotcms.com","googleMap":"AIzaSyDXvD7JA5Q8S5VgfviI8nDinAq9x5Utmu0","modDate":1580831056732,"aliases":"test.dotcms.com\\ntest2.dotcms.com\\nlocalhost\\n127.0.0.1","keywords":"CMS, Web Content Management, Open Source, Java, J2EE, DXP, NoCode, OSGI, Apache Velocity, Elasticsearch, RESTful Services, REST API, Workflows, Personalization, Multilingual, I18N, L10N, Internationalization, Localization, Docker CMS, Containerized CMS","description":"dotCMS starter site was designed to demonstrate what you can do with dotCMS.","type":"host","title":"demo.dotcms.com","proxyEditModeUrl":"https://ematest.dotcms.com:8443","inode":"0c3418eb-4c27-4d71-937d-bf231399312a","hostname":"demo.dotcms.com","__DOTNAME__":"demo.dotcms.com","addThis":"ra-4e02119211875e7b","disabledWYSIWYG":[],"host":"SYSTEM_HOST","lastReview":1580831056724,"stInode":"855a2d72-f2f3-4169-8b04-ac5157c4380c","owner":"dotcms.org.1","nullProperties":["embeddedDashboard","wfExpireDate","wfPublishDate","wfNeverExpire","wfActionAssign","wfActionId","wfPublishTime","wfActionComments","wfExpireTime"],"identifier":"48190c8c-42c4-46af-8d1a-0cd5db894797","runDashboard":false,"languageId":1,"titleImage":"TITLE_IMAGE_NOT_FOUND","isDefault":true,"folder":"SYSTEM_FOLDER","googleAnalytics":"UA-9877660-3","tagStorage":"SYSTEM_HOST","isSystemHost":false,"sortOrder":0,"modUser":"dotcms.org.1","lowIndexPriority":false,"archived":false}}	1585198912023	e64a5620-9bd4-4e08-a53a-67a80079eea1
ee061c7d-5436-48fc-bf7b-8228dca4364f	SESSION_DESTROYED	{"type":"java.lang.Long","visibility":"USER_SESSION","visibilityValue":{"user":"dotcms.org.1","sessionId":"F1E296F17C64A201F487A0E82A4F2ABB"},"visibilityType":"com.dotcms.api.system.event.UserSessionBean","data":1585198987181}	1585198987181	e64a5620-9bd4-4e08-a53a-67a80079eea1
aecb2425-d505-423a-bce4-91951ed245aa	SWITCH_SITE	{"type":"com.dotmarketing.beans.Host","visibility":"USER_SESSION","visibilityValue":{"user":"dotcms.org.1","sessionId":"279683B0145BFFC0D74A62387B9605A0"},"visibilityType":"com.dotcms.api.system.event.UserSessionBean","data":{"hostName":"demo.dotcms.com","googleMap":"AIzaSyDXvD7JA5Q8S5VgfviI8nDinAq9x5Utmu0","modDate":1580831056732,"aliases":"test.dotcms.com\\ntest2.dotcms.com\\nlocalhost\\n127.0.0.1","keywords":"CMS, Web Content Management, Open Source, Java, J2EE, DXP, NoCode, OSGI, Apache Velocity, Elasticsearch, RESTful Services, REST API, Workflows, Personalization, Multilingual, I18N, L10N, Internationalization, Localization, Docker CMS, Containerized CMS","description":"dotCMS starter site was designed to demonstrate what you can do with dotCMS.","type":"host","proxyEditModeUrl":"https://ematest.dotcms.com:8443","inode":"0c3418eb-4c27-4d71-937d-bf231399312a","hostname":"demo.dotcms.com","addThis":"ra-4e02119211875e7b","disabledWYSIWYG":[],"host":"SYSTEM_HOST","lastReview":1580831056724,"stInode":"855a2d72-f2f3-4169-8b04-ac5157c4380c","owner":"dotcms.org.1","nullProperties":["embeddedDashboard","wfExpireDate","wfPublishDate","wfNeverExpire","wfActionAssign","wfActionId","wfPublishTime","wfActionComments","wfExpireTime"],"identifier":"48190c8c-42c4-46af-8d1a-0cd5db894797","runDashboard":false,"languageId":1,"isDefault":true,"folder":"SYSTEM_FOLDER","googleAnalytics":"UA-9877660-3","tagStorage":"SYSTEM_HOST","isSystemHost":false,"sortOrder":0,"modUser":"dotcms.org.1","lowIndexPriority":false,"archived":false}}	1585199305195	e64a5620-9bd4-4e08-a53a-67a80079eea1
58200cde-072c-410e-94b4-20df2cb8223c	SESSION_DESTROYED	{"type":"java.lang.Long","visibility":"USER_SESSION","visibilityValue":{"user":"dotcms.org.1","sessionId":"279683B0145BFFC0D74A62387B9605A0"},"visibilityType":"com.dotcms.api.system.event.UserSessionBean","data":1585199305240}	1585199305240	e64a5620-9bd4-4e08-a53a-67a80079eea1
d878162f-4651-4f62-9ee8-a920edc14d18	SWITCH_SITE	{"type":"com.dotmarketing.beans.Host","visibility":"USER_SESSION","visibilityValue":{"user":"dotcms.org.1","sessionId":"ABDB59E032C1DA277368EAE5E17CA72D"},"visibilityType":"com.dotcms.api.system.event.UserSessionBean","data":{"hostName":"demo.dotcms.com","googleMap":"AIzaSyDXvD7JA5Q8S5VgfviI8nDinAq9x5Utmu0","modDate":1580831056732,"aliases":"test.dotcms.com\\ntest2.dotcms.com\\nlocalhost\\n127.0.0.1","keywords":"CMS, Web Content Management, Open Source, Java, J2EE, DXP, NoCode, OSGI, Apache Velocity, Elasticsearch, RESTful Services, REST API, Workflows, Personalization, Multilingual, I18N, L10N, Internationalization, Localization, Docker CMS, Containerized CMS","description":"dotCMS starter site was designed to demonstrate what you can do with dotCMS.","type":"host","proxyEditModeUrl":"https://ematest.dotcms.com:8443","inode":"0c3418eb-4c27-4d71-937d-bf231399312a","hostname":"demo.dotcms.com","addThis":"ra-4e02119211875e7b","disabledWYSIWYG":[],"host":"SYSTEM_HOST","lastReview":1580831056724,"stInode":"855a2d72-f2f3-4169-8b04-ac5157c4380c","owner":"dotcms.org.1","nullProperties":["embeddedDashboard","wfExpireDate","wfPublishDate","wfNeverExpire","wfActionAssign","wfActionId","wfPublishTime","wfActionComments","wfExpireTime"],"identifier":"48190c8c-42c4-46af-8d1a-0cd5db894797","runDashboard":false,"languageId":1,"isDefault":true,"folder":"SYSTEM_FOLDER","googleAnalytics":"UA-9877660-3","tagStorage":"SYSTEM_HOST","isSystemHost":false,"sortOrder":0,"modUser":"dotcms.org.1","lowIndexPriority":false,"archived":false}}	1585199305245	e64a5620-9bd4-4e08-a53a-67a80079eea1
e9335d4a-e883-47cc-af64-8bd7508a521d	NOTIFICATION	{"type":"com.dotcms.notifications.bean.Notification","visibility":"USER","visibilityValue":"dotcms.org.1","visibilityType":"java.lang.String","data":{"groupId":"68a26a3f-cb70-4a29-b86a-2554435d874b","notificationData":{"title":{"key":""},"message":{"key":"Deletion of user 036fd43a-6d98-46e0-b22e-bae02cb86f0c/Jason Smith has been started. Replacement user: dotcms.org.2808/Admin2 User."}},"level":"INFO","userId":"dotcms.org.1","timeSent":1585199325215,"wasRead":false,"prettyDate":"seconds ago"}}	1585199325215	e64a5620-9bd4-4e08-a53a-67a80079eea1
b3e93d47-b924-43a0-8f26-b89c7259c5f7	NOTIFICATION	{"type":"com.dotcms.notifications.bean.Notification","visibility":"USER","visibilityValue":"dotcms.org.1","visibilityType":"java.lang.String","data":{"groupId":"4bc6e249-7d45-49da-80d1-d9843af511c5","notificationData":{"title":{"key":""},"message":{"key":"Unable to delete user 036fd43a-6d98-46e0-b22e-bae02cb86f0c/Jason Smith."}},"level":"ERROR","userId":"dotcms.org.1","timeSent":1585199325308,"wasRead":false,"prettyDate":"seconds ago"}}	1585199325308	e64a5620-9bd4-4e08-a53a-67a80079eea1
431edaab-5f80-4111-a5ec-bef1d7b0a7d1	NOTIFICATION	{"type":"com.dotcms.notifications.bean.Notification","visibility":"USER","visibilityValue":"dotcms.org.1","visibilityType":"java.lang.String","data":{"groupId":"91558278-d902-4ebd-a0b3-19a0b7fb2f55","notificationData":{"title":{"key":""},"message":{"key":"Deletion of user 036fd43a-6d98-46e0-b22e-bae02cb86f0c/Jason Smith has been started. Replacement user: dotcms.org.2808/Admin2 User."}},"level":"INFO","userId":"dotcms.org.1","timeSent":1585199399451,"wasRead":false,"prettyDate":"seconds ago"}}	1585199399451	e64a5620-9bd4-4e08-a53a-67a80079eea1
fa52ca5d-5c22-45ed-a3a1-2ef2c4ba1e03	NOTIFICATION	{"type":"com.dotcms.notifications.bean.Notification","visibility":"USER","visibilityValue":"dotcms.org.1","visibilityType":"java.lang.String","data":{"groupId":"cd9dac1c-6f8f-4248-8eda-1067255f92fa","notificationData":{"title":{"key":""},"message":{"key":"Unable to delete user 036fd43a-6d98-46e0-b22e-bae02cb86f0c/Jason Smith."}},"level":"ERROR","userId":"dotcms.org.1","timeSent":1585199399499,"wasRead":false,"prettyDate":"seconds ago"}}	1585199399499	e64a5620-9bd4-4e08-a53a-67a80079eea1
e10ba22c-859c-4675-b6f0-105fe35042cb	NOTIFICATION	{"type":"com.dotcms.notifications.bean.Notification","visibility":"ROLE","visibilityValue":"892ab105-f212-407f-8fb4-58ec59310a5e","visibilityType":"java.lang.String","data":{"groupId":"2d1e7408-b8e4-4e27-a263-701028912559","notificationData":{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}},"level":"INFO","userId":"system","timeSent":1585199417105,"wasRead":false,"prettyDate":"seconds ago"}}	1585199417105	e64a5620-9bd4-4e08-a53a-67a80079eea1
9d43aa5b-f515-4761-9a02-f4142fc15858	NOTIFICATION	{"type":"com.dotcms.notifications.bean.Notification","visibility":"ROLE","visibilityValue":"892ab105-f212-407f-8fb4-58ec59310a5e","visibilityType":"java.lang.String","data":{"groupId":"2f215fec-3128-47fa-96f5-daba65ebf779","notificationData":{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}},"level":"INFO","userId":"system","timeSent":1585199420606,"wasRead":false,"prettyDate":"seconds ago"}}	1585199420606	e64a5620-9bd4-4e08-a53a-67a80079eea1
b671aa82-d46b-47c4-8abe-e2cd91904161	NOTIFICATION	{"type":"com.dotcms.notifications.bean.Notification","visibility":"ROLE","visibilityValue":"892ab105-f212-407f-8fb4-58ec59310a5e","visibilityType":"java.lang.String","data":{"groupId":"31a5bd0d-d13b-463b-9145-20d30562cf7e","notificationData":{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}},"level":"INFO","userId":"system","timeSent":1585199424108,"wasRead":false,"prettyDate":"seconds ago"}}	1585199424108	e64a5620-9bd4-4e08-a53a-67a80079eea1
3ab622d1-500e-4c9a-904d-87efa3e58fa3	NOTIFICATION	{"type":"com.dotcms.notifications.bean.Notification","visibility":"ROLE","visibilityValue":"892ab105-f212-407f-8fb4-58ec59310a5e","visibilityType":"java.lang.String","data":{"groupId":"017f57cd-c634-490e-a95b-704349251d52","notificationData":{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}},"level":"INFO","userId":"system","timeSent":1585199427612,"wasRead":false,"prettyDate":"seconds ago"}}	1585199427612	e64a5620-9bd4-4e08-a53a-67a80079eea1
d250d8bb-553f-41ac-a974-e8318a1e831f	NOTIFICATION	{"type":"com.dotcms.notifications.bean.Notification","visibility":"ROLE","visibilityValue":"892ab105-f212-407f-8fb4-58ec59310a5e","visibilityType":"java.lang.String","data":{"groupId":"af31cf71-fb72-4d54-bff4-dfc6f386563c","notificationData":{"title":{"key":"notification.reindex.error.title"},"message":{"key":"notification.reindexing.success"}},"level":"INFO","userId":"system","timeSent":1585199428179,"wasRead":false,"prettyDate":"seconds ago"}}	1585199428179	e64a5620-9bd4-4e08-a53a-67a80079eea1
\.


--
-- Data for Name: tag; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.tag (tag_id, tagname, host_id, user_id, persona, mod_date) FROM stdin;
23dcbb8c-54ce-468a-b286-3e5b2047fc4f	mountain	SYSTEM_HOST		t	2019-09-09 16:05:25.565
257e727b-f686-4952-8135-ca2dc353a978	skier	SYSTEM_HOST		t	2019-10-18 17:05:19.938
4dfa7e15-c397-41f0-b36c-10cbc367f591	wealthlyprospect	48190c8c-42c4-46af-8d1a-0cd5db894797		t	2016-02-19 12:21:11.842
ab344fa0-c909-4b3c-aa8c-6bacd4f770fa	beach	SYSTEM_HOST		t	2019-09-05 16:54:46.248
afba7a15-3378-4a0d-a411-b91b8f35f498	surfer	SYSTEM_HOST		t	2019-10-18 16:04:43.987
dee7c4cb-1c42-41dc-b6a5-51a1e283cc76	metropolitan	SYSTEM_HOST		t	2019-09-09 16:09:52.345
f0993166-769e-4889-946e-9da2723a8989	hiker	SYSTEM_HOST		t	2019-10-18 17:14:33.579
\.


--
-- Data for Name: tag_inode; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.tag_inode (tag_id, inode, field_var_name, mod_date) FROM stdin;
4dfa7e15-c397-41f0-b36c-10cbc367f591	03056dc5-ac54-4439-9648-5b7667a38b00	tags	2016-02-18 12:17:36.575
4dfa7e15-c397-41f0-b36c-10cbc367f591	06f14b6c-cdfa-46f5-aa40-f66504d65415	tags	2016-02-18 12:17:36.529
ab344fa0-c909-4b3c-aa8c-6bacd4f770fa	08393243-9a80-4131-ac11-4ccf6332ab85	tags	2019-09-06 18:30:40.137
257e727b-f686-4952-8135-ca2dc353a978	08ca6cdb-9159-4b96-8c49-f69cae5224f5	tags	2019-10-24 17:02:48.658
23dcbb8c-54ce-468a-b286-3e5b2047fc4f	1ba10e89-af0e-41d9-847b-8cc73fddb7fb	tags	2019-09-11 14:10:21.497
ab344fa0-c909-4b3c-aa8c-6bacd4f770fa	1c332647-c598-4227-921a-c08b6c019107	tags	2019-11-05 15:51:27.873
ab344fa0-c909-4b3c-aa8c-6bacd4f770fa	28457fcb-cb75-4b7c-8238-477472dac1b0	tags	2019-09-06 18:30:40.128
4dfa7e15-c397-41f0-b36c-10cbc367f591	28cb338d-5c9e-4a02-955f-7c8d7d327a5e	tags	2016-02-18 12:17:36.264
4dfa7e15-c397-41f0-b36c-10cbc367f591	290e21ba-bd08-4073-896c-5d0407052c88	tags	2016-02-18 12:17:36.091
afba7a15-3378-4a0d-a411-b91b8f35f498	2f0a84a3-2e6f-4bf4-afe2-68fac59647b3	tags	2019-10-18 17:21:52.463
257e727b-f686-4952-8135-ca2dc353a978	30b32049-890b-4207-8c90-300a456fd6b8	tags	2019-10-18 17:24:00.423
23dcbb8c-54ce-468a-b286-3e5b2047fc4f	334b850a-5092-4dd2-b391-633093a1f24a	tags	2019-09-20 16:58:17.296
4dfa7e15-c397-41f0-b36c-10cbc367f591	34035da7-effb-4cf0-8869-af3bfdb008cd	tags	2016-02-18 12:17:36.555
ab344fa0-c909-4b3c-aa8c-6bacd4f770fa	353aaad2-dc44-4b0b-9a02-4cead7d4aaeb	tags	2019-09-06 19:20:42.279
ab344fa0-c909-4b3c-aa8c-6bacd4f770fa	3e3909ab-c761-4f03-b4cb-a41bcc6a3db0	tags	2019-10-18 13:40:39.936
4dfa7e15-c397-41f0-b36c-10cbc367f591	402afa6e-1ffe-4717-853b-ee46b5d29f89	tags	2016-02-18 12:17:36.274
4dfa7e15-c397-41f0-b36c-10cbc367f591	490ffde6-8487-43df-9eff-74646e70cf73	tags	2016-02-18 12:17:36.547
4dfa7e15-c397-41f0-b36c-10cbc367f591	505e4a67-cd1b-4320-b1f4-199e4ccc96ec	tags	2016-02-18 12:17:36.545
ab344fa0-c909-4b3c-aa8c-6bacd4f770fa	506a5b34-114d-41ce-81c9-5f8318f2b6f0	tags	2019-09-20 10:19:44.85
257e727b-f686-4952-8135-ca2dc353a978	515ab07d-2c9a-4ff5-bf46-a5cb6cd39141	tags	2019-10-24 17:03:07.531
4dfa7e15-c397-41f0-b36c-10cbc367f591	55108e77-5bee-4a91-951f-3324a18a284d	tags	2016-02-18 12:17:36.182
afba7a15-3378-4a0d-a411-b91b8f35f498	55b66e50-7819-466b-8cf6-7778374e53d8	tags	2019-10-18 17:23:11.689
ab344fa0-c909-4b3c-aa8c-6bacd4f770fa	56d6b160-a248-44b6-bfdf-2d51ca23df82	tags	2019-10-18 13:38:33.374
ab344fa0-c909-4b3c-aa8c-6bacd4f770fa	5f8dc05d-d43b-4afb-8d55-f0fe5b2689c1	tags	2019-09-06 18:30:40.127
ab344fa0-c909-4b3c-aa8c-6bacd4f770fa	63f71055-bf1c-4e55-84a1-508a0ef70e44	tags	2019-09-11 13:13:48.907
4dfa7e15-c397-41f0-b36c-10cbc367f591	6589d863-bb6e-407a-93ab-7ac870e69a65	tags	2016-02-18 12:17:36.208
4dfa7e15-c397-41f0-b36c-10cbc367f591	65dace87-796d-4444-a1a6-27d806a21c45	tags	2016-02-18 12:17:36.107
afba7a15-3378-4a0d-a411-b91b8f35f498	66496c93-5e99-4e56-86b0-a1aa4c627fc0	tags	2019-10-22 15:25:22.06
ab344fa0-c909-4b3c-aa8c-6bacd4f770fa	696956e5-771f-4fd1-9bde-14397edf907c	tags	2019-09-06 18:30:40.128
ab344fa0-c909-4b3c-aa8c-6bacd4f770fa	6b33fddc-8732-4c43-a233-ddb5829b82ad	tags	2019-11-05 15:52:47.201
ab344fa0-c909-4b3c-aa8c-6bacd4f770fa	784f8b37-f0a7-415a-a6c8-7632bdd16df5	tags	2019-09-10 12:56:27.172
ab344fa0-c909-4b3c-aa8c-6bacd4f770fa	788f516e-c013-4cde-a782-815e5caf449b	tags	2019-11-05 15:53:10.086
ab344fa0-c909-4b3c-aa8c-6bacd4f770fa	79a4ad04-b8b9-40d4-b9a6-55883c108564	tags	2019-10-18 13:39:00.71
ab344fa0-c909-4b3c-aa8c-6bacd4f770fa	7dbb1cb6-1058-46ff-adf4-21bce8f63216	tags	2019-09-20 10:31:10.671
ab344fa0-c909-4b3c-aa8c-6bacd4f770fa	7f2f67f2-bc65-4b2b-a2f4-742d761682da	tags	2019-12-11 10:19:34.236
ab344fa0-c909-4b3c-aa8c-6bacd4f770fa	81ab4c42-2cb0-4d32-922f-55f22331be3d	tags	2019-09-19 18:09:14.243
afba7a15-3378-4a0d-a411-b91b8f35f498	81b78a9d-375d-4f39-8934-825f0129fbc8	tags	2019-10-18 17:25:51.492
ab344fa0-c909-4b3c-aa8c-6bacd4f770fa	87ffc0d4-c3c0-45bd-8930-8fb98493a766	tags	2019-09-06 19:19:48.256
afba7a15-3378-4a0d-a411-b91b8f35f498	8ba935b7-f681-4aca-b552-24332cae622f	tags	2019-10-22 16:09:40.879
4dfa7e15-c397-41f0-b36c-10cbc367f591	93c7ab09-8cd9-4a5f-b917-37c075c552ad	tags	2016-02-18 12:17:36.55
4dfa7e15-c397-41f0-b36c-10cbc367f591	97dd86db-fd9f-4b39-bbc9-8f5d257444c0	tags	2016-02-18 12:17:36.077
ab344fa0-c909-4b3c-aa8c-6bacd4f770fa	a0bf15bf-a285-4fe0-8284-cbded952aecb	tags	2019-09-10 12:56:37.445
4dfa7e15-c397-41f0-b36c-10cbc367f591	a14c32d2-64f4-498e-bba7-cb0ad30cce94	tags	2016-02-18 12:17:36.594
afba7a15-3378-4a0d-a411-b91b8f35f498	a4021587-196c-4d0f-a058-eae7310f2187	tags	2019-10-18 17:21:28.358
4dfa7e15-c397-41f0-b36c-10cbc367f591	a7462a9a-bb59-4732-a59b-64a1b11316ab	tags	2016-02-18 12:17:36.565
afba7a15-3378-4a0d-a411-b91b8f35f498	aabecf51-74f1-4a67-85ee-91211fb9a0e1	tags	2019-10-18 17:26:09.488
4dfa7e15-c397-41f0-b36c-10cbc367f591	acea345b-015f-4de8-8000-9fc94aed05a4	tags	2016-02-18 12:17:36.573
4dfa7e15-c397-41f0-b36c-10cbc367f591	b4041a12-e084-4adc-8dfa-e95ffa35ef28	tags	2016-02-18 12:17:36.131
ab344fa0-c909-4b3c-aa8c-6bacd4f770fa	b82852b6-1b26-46fb-9ad3-46eb57b3f4d0	tags	2019-10-02 14:29:24.281
ab344fa0-c909-4b3c-aa8c-6bacd4f770fa	c3c6b62d-552b-49f8-85c2-ed02e3ab196e	tags	2019-09-11 13:19:28.188
4dfa7e15-c397-41f0-b36c-10cbc367f591	cfd589bd-d202-4430-a4b0-aa33a8af68d2	tags	2016-02-18 12:17:36.532
23dcbb8c-54ce-468a-b286-3e5b2047fc4f	e17f953c-1af8-4bab-9142-82af8f852da5	tags	2019-09-11 14:08:32.797
afba7a15-3378-4a0d-a411-b91b8f35f498	e79a65df-3c02-482c-bd76-3958bfe0f591	tags	2019-10-18 17:26:20.806
ab344fa0-c909-4b3c-aa8c-6bacd4f770fa	ead9303d-4c88-4a13-be24-2615a006fa32	tags	2019-09-06 18:32:26.643
ab344fa0-c909-4b3c-aa8c-6bacd4f770fa	ec5c6e2f-4266-4ff8-adfc-22f76ba453b7	tags	2019-09-19 18:08:27.816
ab344fa0-c909-4b3c-aa8c-6bacd4f770fa	ed320537-a91e-4624-b9bc-d63863c3b055	tags	2019-10-18 13:39:40.252
ab344fa0-c909-4b3c-aa8c-6bacd4f770fa	efc0ba72-176f-4a89-8b40-5a6fedd2e971	tags	2019-09-19 18:13:13.294
afba7a15-3378-4a0d-a411-b91b8f35f498	f17f02ca-397c-4911-949e-b02f143c366a	tags	2019-10-22 16:30:29.167
4dfa7e15-c397-41f0-b36c-10cbc367f591	f79a6391-b30f-47a4-8d35-abae06b192bd	tags	2016-02-18 12:17:36.552
257e727b-f686-4952-8135-ca2dc353a978	fbba1531-46d8-4bac-9fca-603afa09cb0a	tags	2019-10-24 17:03:31.666
ab344fa0-c909-4b3c-aa8c-6bacd4f770fa	fbd56d05-bf75-427d-8a2f-d964398da3d8	tags	2019-09-11 13:10:55.254
257e727b-f686-4952-8135-ca2dc353a978	fdbedbfa-a6c0-4c7b-9009-32deb585c28a	tags	2019-10-24 16:23:27.073
4dfa7e15-c397-41f0-b36c-10cbc367f591	fec1d734-fffb-41fb-b039-e616b0335440	tags	2016-02-18 12:17:36.618
\.


--
-- Data for Name: template; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.template (inode, show_on_menu, title, mod_date, mod_user, sort_order, friendly_name, body, header, footer, image, identifier, drawed, drawed_body, add_container_links, containers_added, head_code, theme) FROM stdin;
8a780107-a9fe-4871-ab31-32c7d920518b	f	anonymous_layout_1581449871124	2020-02-11 14:37:51.16	dotcms.org.2808	0		\N	\N	\N		9b9e7218-e086-4c61-991f-6ec22e7d7a82	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"1"}],"widthPercent":100,"leftOffset":1,"preview":false,"width":12,"left":0}],"styleClass":"fluid"},{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"2"}],"widthPercent":66,"leftOffset":3,"preview":false,"width":8,"left":2}],"styleClass":"mb-2"},{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"3"}],"widthPercent":100,"leftOffset":1,"styleClass":"","preview":false,"width":12,"left":0}]}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	d7b0ebc2-37ca-4a5a-b769-e8a3ff187661
be5383eb-fa12-4884-bdc8-7c2cb516c5b5	f	anonymous_layout_1581105203001	2020-02-07 14:53:23.085	dotcms.org.2808	0		\N	\N	\N		9b9e7218-e086-4c61-991f-6ec22e7d7a82	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"1"}],"widthPercent":100,"leftOffset":1,"preview":false,"width":12,"left":0}],"styleClass":"fluid"},{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"2"}],"widthPercent":83,"leftOffset":2,"preview":false,"width":10,"left":1}],"styleClass":"mb-2"},{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"3"}],"widthPercent":100,"leftOffset":1,"styleClass":"","preview":false,"width":12,"left":0}]}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	d7b0ebc2-37ca-4a5a-b769-e8a3ff187661
cfda9246-cce3-4313-8cc3-2080d1935cf9	f	anonymous_layout_1579716181795	2020-01-22 13:03:01.879	dotcms.org.2808	0		\N	\N	\N		0c556e37-99e0-4458-a2cd-d42cc7a11045	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"5a07f889-4536-4956-aa6e-e7967969ec3f","uuid":"1"}],"widthPercent":100,"leftOffset":1,"preview":false,"width":12,"left":0}]},{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"1"}],"widthPercent":50,"leftOffset":1,"styleClass":"","preview":false,"width":6,"left":0},{"containers":[{"identifier":"/application/containers/default/","uuid":"2"}],"widthPercent":50,"leftOffset":7,"styleClass":"","preview":false,"width":6,"left":6}]},{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"3"}],"widthPercent":100,"leftOffset":1,"styleClass":"","preview":false,"width":12,"left":0}]},{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"4"}],"widthPercent":83,"leftOffset":2,"styleClass":"","preview":false,"width":10,"left":1}]},{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"5"}],"widthPercent":50,"leftOffset":1,"styleClass":"","preview":false,"width":6,"left":0},{"containers":[{"identifier":"/application/containers/default/","uuid":"6"}],"widthPercent":50,"leftOffset":7,"styleClass":"","preview":false,"width":6,"left":6}]},{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"7"}],"widthPercent":41,"leftOffset":1,"styleClass":"","preview":false,"width":5,"left":0},{"containers":[{"identifier":"/application/containers/default/","uuid":"8"}],"widthPercent":50,"leftOffset":7,"styleClass":"","preview":false,"width":6,"left":6}]}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	d7b0ebc2-37ca-4a5a-b769-e8a3ff187661
a0867428-0bdb-4191-af2f-4c19637ef40b	f	anonymous_layout_1573225905984	2019-11-08 10:11:46.028	036fd43a-6d98-46e0-b22e-bae02cb86f0c	0		\N	\N	\N		9469fbf0-9fc2-451d-94d9-5fbfde5b5974	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"5a07f889-4536-4956-aa6e-e7967969ec3f","uuid":"1"}],"widthPercent":100,"leftOffset":1,"preview":false,"width":12,"left":0}]},{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"1"}],"widthPercent":50,"leftOffset":1,"preview":false,"width":6,"left":0},{"containers":[{"identifier":"/application/containers/default/","uuid":"2"}],"widthPercent":50,"leftOffset":7,"preview":false,"width":6,"left":6}],"styleClass":""},{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"3"}],"widthPercent":100,"leftOffset":1,"styleClass":"","preview":false,"width":12,"left":0}],"styleClass":""},{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"4"}],"widthPercent":100,"leftOffset":1,"styleClass":"","preview":false,"width":12,"left":0}],"styleClass":"mb-2"},{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"5"}],"widthPercent":33,"leftOffset":1,"preview":false,"width":4,"left":0},{"containers":[{"identifier":"/application/containers/default/","uuid":"6"}],"widthPercent":33,"leftOffset":5,"styleClass":"","preview":false,"width":4,"left":4},{"containers":[{"identifier":"/application/containers/default/","uuid":"7"}],"widthPercent":33,"leftOffset":9,"styleClass":"","preview":false,"width":4,"left":8}]},{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"8"}],"widthPercent":100,"leftOffset":1,"styleClass":"text-center","preview":false,"width":12,"left":0}],"styleClass":""},{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"9"}],"widthPercent":33,"leftOffset":1,"styleClass":"","preview":false,"width":4,"left":0},{"containers":[{"identifier":"/application/containers/default/","uuid":"10"}],"widthPercent":33,"leftOffset":5,"styleClass":"","preview":false,"width":4,"left":4},{"containers":[{"identifier":"/application/containers/default/","uuid":"11"}],"widthPercent":33,"leftOffset":9,"styleClass":"","preview":false,"width":4,"left":8}]}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	d7b0ebc2-37ca-4a5a-b769-e8a3ff187661
4def88a9-de8c-4f18-a9ca-f75e9cc516f5	f	anonymous_layout_1573064793546	2019-11-06 13:26:33.581	036fd43a-6d98-46e0-b22e-bae02cb86f0c	0		\N	\N	\N		ea887e3a-1e9d-47cf-995a-ce060ae1fc4e	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"1"}],"widthPercent":41,"leftOffset":1,"preview":false,"width":5,"left":0},{"containers":[{"identifier":"/application/containers/default/","uuid":"2"}],"widthPercent":50,"leftOffset":7,"styleClass":"","preview":false,"width":6,"left":6}]},{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"3"}],"widthPercent":50,"leftOffset":1,"preview":false,"width":6,"left":0},{"containers":[{"identifier":"/application/containers/default/","uuid":"4"}],"widthPercent":50,"leftOffset":7,"preview":false,"width":6,"left":6}]},{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"5"}],"widthPercent":25,"leftOffset":1,"preview":false,"width":3,"left":0},{"containers":[{"identifier":"/application/containers/default/","uuid":"6"}],"widthPercent":25,"leftOffset":4,"preview":false,"width":3,"left":3},{"containers":[{"identifier":"/application/containers/default/","uuid":"7"}],"widthPercent":25,"leftOffset":7,"preview":false,"width":3,"left":6},{"containers":[{"identifier":"/application/containers/default/","uuid":"8"}],"widthPercent":25,"leftOffset":10,"preview":false,"width":3,"left":9}]},{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"9"}],"widthPercent":100,"leftOffset":1,"preview":false,"width":12,"left":0}],"styleClass":"fluid"}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	ce00bd28-5f66-47f9-96ca-bbf0722a79aa
ae0ea552-4a97-483b-b456-1c304491a5d5	f	anonymous_layout_1572528073274	2019-10-31 09:21:13.319	036fd43a-6d98-46e0-b22e-bae02cb86f0c	0		\N	\N	\N		95e0af1d-bf6a-46ca-b0f7-665b23d00be3	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"1"}],"widthPercent":100,"leftOffset":1,"styleClass":"","preview":false,"width":12,"left":0}],"styleClass":"section-md"}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	d7b0ebc2-37ca-4a5a-b769-e8a3ff187661
8ab7a996-318d-48c1-baf4-62d6f0ce134a	f	anonymous_layout_1572292920222	2019-10-28 16:02:00.6	036fd43a-6d98-46e0-b22e-bae02cb86f0c	0		\N	\N	\N		fdc739f6-fe53-4271-9c8c-a3e05d12fcac	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"5a07f889-4536-4956-aa6e-e7967969ec3f","uuid":"1"}],"widthPercent":100,"leftOffset":1,"styleClass":"banner-tall","preview":false,"width":12,"left":0}],"styleClass":"p-0 banner-tall"},{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"1"}],"widthPercent":100,"leftOffset":1,"styleClass":"mt-70","preview":false,"width":12,"left":0}],"styleClass":""},{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"2"}],"widthPercent":25,"leftOffset":1,"styleClass":"","preview":false,"width":3,"left":0},{"containers":[{"identifier":"/application/containers/default/","uuid":"3"}],"widthPercent":25,"leftOffset":4,"styleClass":"","preview":false,"width":3,"left":3},{"containers":[{"identifier":"/application/containers/default/","uuid":"4"}],"widthPercent":25,"leftOffset":7,"styleClass":"","preview":false,"width":3,"left":6},{"containers":[{"identifier":"/application/containers/default/","uuid":"5"}],"widthPercent":25,"leftOffset":10,"styleClass":"","preview":false,"width":3,"left":9}],"styleClass":"mt-4 mb-3"},{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"6"}],"widthPercent":50,"leftOffset":1,"styleClass":"","preview":false,"width":6,"left":0},{"containers":[{"identifier":"/application/containers/default/","uuid":"7"}],"widthPercent":25,"leftOffset":7,"styleClass":"","preview":false,"width":3,"left":6},{"containers":[{"identifier":"/application/containers/default/","uuid":"8"}],"widthPercent":25,"leftOffset":10,"styleClass":"","preview":false,"width":3,"left":9}],"styleClass":""},{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"9"}],"widthPercent":100,"leftOffset":1,"styleClass":"","preview":false,"width":12,"left":0}],"styleClass":"section-md"},{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"10"}],"widthPercent":50,"leftOffset":1,"styleClass":"wow fadeInUp","preview":false,"width":6,"left":0},{"containers":[{"identifier":"/application/containers/default/","uuid":"11"}],"widthPercent":50,"leftOffset":7,"styleClass":"pl-lg-5","preview":false,"width":6,"left":6}],"styleClass":"section-xl bg-white"},{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"12"}],"widthPercent":100,"leftOffset":1,"styleClass":"","preview":false,"width":12,"left":0}],"styleClass":"section-md"},{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"13"}],"widthPercent":100,"leftOffset":1,"styleClass":"","preview":false,"width":12,"left":0}]}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	d7b0ebc2-37ca-4a5a-b769-e8a3ff187661
a2ed6aec-ecd7-4390-a4d4-d3047424fc84	f	anonymous_layout_1568912466963	2019-09-19 13:01:06.995	dotcms.org.1	0		\N	\N	\N		965059bc-25b4-44b0-add8-b6fc5144be9d	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"1"}],"widthPercent":66,"leftOffset":3,"preview":false,"width":8,"left":2}],"styleClass":"section-xxl"}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	d7b0ebc2-37ca-4a5a-b769-e8a3ff187661
2162bbbb-ec25-47ff-8e05-f70f6125981d	f	anonymous_layout_1571928655984	2019-10-24 10:50:56.147	036fd43a-6d98-46e0-b22e-bae02cb86f0c	0		\N	\N	\N		c2470fd2-9687-4041-ac58-784894171840	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"5a07f889-4536-4956-aa6e-e7967969ec3f","uuid":"1"}],"widthPercent":100,"leftOffset":1,"preview":false,"width":12,"left":0}]},{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"1"}],"widthPercent":100,"leftOffset":1,"styleClass":"text-2-col","preview":false,"width":12,"left":0}]},{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"2"}],"widthPercent":100,"leftOffset":1,"styleClass":"","preview":false,"width":12,"left":0}]},{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"3"}],"widthPercent":50,"leftOffset":1,"preview":false,"width":6,"left":0},{"containers":[{"identifier":"/application/containers/default/","uuid":"4"}],"widthPercent":50,"leftOffset":7,"preview":false,"width":6,"left":6}]}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	d7b0ebc2-37ca-4a5a-b769-e8a3ff187661
1b8e9931-cbea-4ee7-b2b0-2c5911b4e575	f	anonymous_layout_1571782273525	2019-10-22 18:11:13.594	036fd43a-6d98-46e0-b22e-bae02cb86f0c	0		\N	\N	\N		593ef32c-2f01-4277-a6a9-2250fd5bb5fe	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"1"}],"widthPercent":100,"leftOffset":1,"preview":false,"width":12,"left":0}],"styleClass":"section-md"}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	d7b0ebc2-37ca-4a5a-b769-e8a3ff187661
f9455e7a-bd1a-4cb7-9556-b7ede4f93fc3	f	anonymous_layout_1571406924828	2019-10-18 09:55:24.919	036fd43a-6d98-46e0-b22e-bae02cb86f0c	0		\N	\N	\N		64269d16-2710-4919-88ec-3b09c89ea004	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"1"}],"widthPercent":83,"leftOffset":2,"styleClass":"","preview":false,"width":10,"left":1}],"styleClass":"section-sm mb-0"},{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"2"}],"widthPercent":100,"leftOffset":1,"preview":false,"width":12,"left":0}]}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	d7b0ebc2-37ca-4a5a-b769-e8a3ff187661
a7d001e5-d6e8-4f82-9d08-ea7487e2689f	f	anonymous_layout_1570466708206	2019-10-07 12:45:08.361	036fd43a-6d98-46e0-b22e-bae02cb86f0c	0		\N	\N	\N		683ea6c2-5d33-4363-8061-c811b1381f25	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"1"}],"widthPercent":50,"leftOffset":1,"styleClass":"text-white","preview":false,"width":6,"left":0},{"containers":[{"identifier":"/application/containers/default/","uuid":"2"}],"widthPercent":41,"leftOffset":8,"styleClass":"img-stack","preview":false,"width":5,"left":7}],"styleClass":""},{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"3"}],"widthPercent":50,"leftOffset":1,"preview":false,"width":6,"left":0},{"containers":[{"identifier":"/application/containers/default/","uuid":"4"}],"widthPercent":50,"leftOffset":7,"preview":false,"width":6,"left":6}]},{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"5"}],"widthPercent":25,"leftOffset":1,"preview":false,"width":3,"left":0},{"containers":[{"identifier":"/application/containers/default/","uuid":"6"}],"widthPercent":25,"leftOffset":4,"preview":false,"width":3,"left":3},{"containers":[{"identifier":"/application/containers/default/","uuid":"7"}],"widthPercent":25,"leftOffset":7,"preview":false,"width":3,"left":6},{"containers":[{"identifier":"/application/containers/default/","uuid":"8"}],"widthPercent":25,"leftOffset":10,"preview":false,"width":3,"left":9}]},{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"9"}],"widthPercent":100,"leftOffset":1,"preview":false,"width":12,"left":0}],"styleClass":"fluid no-gutters"}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	ce00bd28-5f66-47f9-96ca-bbf0722a79aa
d1113914-c2e4-4067-8c3a-68981d786a75	f	anonymous_layout_1570203184565	2019-10-04 11:33:04.573	036fd43a-6d98-46e0-b22e-bae02cb86f0c	0		\N	\N	\N		69370958-2898-4d1e-96ad-ab14278ad961	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"1"}],"widthPercent":100,"leftOffset":1,"preview":false,"width":12,"left":0}]},{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"2"}],"widthPercent":50,"leftOffset":1,"preview":false,"width":6,"left":0},{"containers":[{"identifier":"/application/containers/default/","uuid":"3"}],"widthPercent":25,"leftOffset":7,"preview":false,"width":3,"left":6}]},{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"4"}],"widthPercent":25,"leftOffset":1,"preview":false,"width":3,"left":0},{"containers":[{"identifier":"/application/containers/default/","uuid":"5"}],"widthPercent":25,"leftOffset":4,"preview":false,"width":3,"left":3},{"containers":[{"identifier":"/application/containers/default/","uuid":"6"}],"widthPercent":25,"leftOffset":7,"preview":false,"width":3,"left":6},{"containers":[{"identifier":"/application/containers/default/","uuid":"7"}],"widthPercent":25,"leftOffset":10,"preview":false,"width":3,"left":9}]},{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"8"}],"widthPercent":100,"leftOffset":1,"preview":false,"width":12,"left":0}]}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	ce00bd28-5f66-47f9-96ca-bbf0722a79aa
0856a795-cba1-488a-ba13-f10f2983a42d	f	anonymous_layout_1569272747550	2019-09-23 17:05:47.641	dotcms.org.1	0		\N	\N	\N		0b280c00-834f-4721-a48e-2f4df97607ea	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"5a07f889-4536-4956-aa6e-e7967969ec3f","uuid":"1"}],"widthPercent":100,"leftOffset":1,"preview":false,"width":12,"left":0}]},{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"1"}],"widthPercent":50,"leftOffset":1,"preview":false,"width":6,"left":0},{"containers":[{"identifier":"/application/containers/default/","uuid":"2"}],"widthPercent":50,"leftOffset":7,"preview":false,"width":6,"left":6}]},{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"3"}],"widthPercent":100,"leftOffset":1,"styleClass":"","preview":false,"width":12,"left":0}],"styleClass":""},{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"4"}],"widthPercent":100,"leftOffset":1,"styleClass":"","preview":false,"width":12,"left":0}],"styleClass":""},{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"5"}],"widthPercent":100,"leftOffset":1,"styleClass":"","preview":false,"width":12,"left":0}],"styleClass":"fluid mb-0"}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	d7b0ebc2-37ca-4a5a-b769-e8a3ff187661
fa0a5930-c733-4a8f-91bf-d4bad9d1ea9e	f	anonymous_layout_1569008928315	2019-09-20 15:48:48.426	dotcms.org.1	0		\N	\N	\N		a9d7d59a-8ff8-4ee3-84c0-e49f6312b185	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"1"}],"widthPercent":83,"leftOffset":2,"preview":false,"width":10,"left":1}],"styleClass":"mt-5 mb-1"},{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"2"}],"widthPercent":100,"leftOffset":1,"styleClass":"","preview":false,"width":12,"left":0}]}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	d7b0ebc2-37ca-4a5a-b769-e8a3ff187661
1d83162a-edaf-412b-b004-295992eb5caa	f	anonymous_layout_1568912250058	2019-09-19 12:57:30.088	dotcms.org.1	0		\N	\N	\N		965059bc-25b4-44b0-add8-b6fc5144be9d	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"1"}],"widthPercent":66,"leftOffset":3,"preview":false,"width":8,"left":2}]}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	d7b0ebc2-37ca-4a5a-b769-e8a3ff187661
b2440bc7-f3d0-4bd8-8fa5-28952fd37f62	f	anonymous_layout_1568833035354	2019-09-18 14:57:15.381	dotcms.org.1	0		\N	\N	\N		bca97d30-14f3-418d-8827-a2799c5e9a0c	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"794f91e8-d7e4-43dd-a671-1157fc983821","uuid":"1"}],"widthPercent":100,"leftOffset":1,"preview":false,"width":12,"left":0}]},{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"1"}],"widthPercent":100,"leftOffset":1,"preview":false,"width":12,"left":0}],"styleClass":""}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	d7b0ebc2-37ca-4a5a-b769-e8a3ff187661
54b4cf8d-0538-4862-a392-e544bb865c38	f	anonymous_layout_1566249745610	2019-08-19 17:22:26.045	dotcms.org.1	0		\N	\N	\N		040d7fdf-fb31-4a92-867b-a67bccdfca29	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"1"}],"widthPercent":100,"leftOffset":1,"styleClass":"","preview":false,"width":12,"left":0}],"styleClass":"fluid mb-5"},{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"2"}],"widthPercent":50,"leftOffset":1,"styleClass":"col-md-6","preview":false,"width":6,"left":0},{"containers":[{"identifier":"/application/containers/default/","uuid":"3"}],"widthPercent":41,"leftOffset":8,"styleClass":"col-md-6","preview":false,"width":5,"left":7}],"styleClass":""},{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"4"}],"widthPercent":33,"leftOffset":1,"styleClass":"","preview":false,"width":4,"left":0},{"containers":[{"identifier":"/application/containers/default/","uuid":"5"}],"widthPercent":33,"leftOffset":5,"preview":false,"width":4,"left":4},{"containers":[{"identifier":"/application/containers/default/","uuid":"6"}],"widthPercent":25,"leftOffset":10,"styleClass":"","preview":false,"width":3,"left":9}],"styleClass":"justify-content-between mb-5"},{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"7"}],"widthPercent":33,"leftOffset":1,"styleClass":"","preview":false,"width":4,"left":0},{"containers":[{"identifier":"/application/containers/default/","uuid":"8"}],"widthPercent":33,"leftOffset":5,"styleClass":"","preview":false,"width":4,"left":4},{"containers":[{"identifier":"/application/containers/default/","uuid":"9"}],"widthPercent":33,"leftOffset":9,"styleClass":"","preview":false,"width":4,"left":8}],"styleClass":"justify-content-between mb-5 pb-5"},{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"10"}],"widthPercent":100,"leftOffset":1,"styleClass":"","preview":false,"width":12,"left":0}],"styleClass":"fluid"},{"columns":[{"containers":[],"widthPercent":25,"leftOffset":1,"styleClass":"","preview":false,"width":3,"left":0}]}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	d7b0ebc2-37ca-4a5a-b769-e8a3ff187661
543b5efa-eb96-4868-8bad-1d96e99ab93f	f	anonymous_layout_1564407003686	2019-07-29 09:30:03.733	dotcms.org.1	0		\N	\N	\N		ba1002d7-d4db-4019-b242-8118054051a4	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"1"}],"widthPercent":100,"leftOffset":1,"preview":false,"width":12,"left":0}],"styleClass":"fluid"}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	d7b0ebc2-37ca-4a5a-b769-e8a3ff187661
9164f879-b4bb-46de-a306-4cdd7952253d	f	anonymous_layout_1564080151538	2019-07-25 14:42:31.559	dotcms.org.1	0		\N	\N	\N		50042108-38ec-48ba-be91-7f4368c8630f	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"1"}],"widthPercent":100,"leftOffset":1,"preview":false,"width":12,"left":0}],"styleClass":"section-xxl"}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	d7b0ebc2-37ca-4a5a-b769-e8a3ff187661
b7046ed2-ccf0-45c6-8819-d4c3994ce765	f	anonymous_layout_1563464673381	2019-07-18 11:44:33.401	dotcms.org.1	0		\N	\N	\N		2b457e67-9c94-4cb3-8d1b-422fbe4fd5a0	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"1"}],"widthPercent":100,"leftOffset":1,"styleClass":"","preview":false,"width":12,"left":0}],"styleClass":"fluid"}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	d7b0ebc2-37ca-4a5a-b769-e8a3ff187661
98d027b1-189d-41e2-adba-9f873b593e86	f	anonymous_layout_1563312409674	2019-07-16 17:26:49.699	dotcms.org.1	0		\N	\N	\N		35fe888d-1555-43ad-b155-080dd7d9b9cf	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"1"}],"widthPercent":100,"leftOffset":1,"preview":false,"width":12,"left":0}],"styleClass":"section-xxl"}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	d7b0ebc2-37ca-4a5a-b769-e8a3ff187661
8b823726-37c0-487e-a0d8-7e10ea57ea94	f	anonymous_layout_1563211383718	2019-07-15 13:23:03.81	dotcms.org.1	0		\N	\N	\N		e357b275-3cc8-455b-b7d7-0adaefb51040	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"1"}],"widthPercent":83,"leftOffset":2,"preview":false,"width":10,"left":1}],"styleClass":"section-xxl"}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	d7b0ebc2-37ca-4a5a-b769-e8a3ff187661
80d27245-8e05-42b4-955b-c48811b8b24e	f	anonymous_layout_1562705268252	2019-07-09 16:47:48.261	dotcms.org.1	0		\N	\N	\N		3826636b-cc3a-46b2-97c5-ce6bdb377fcb	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"1"}],"widthPercent":100,"leftOffset":1,"preview":false,"width":12,"left":0}],"identifier":0}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	d7b0ebc2-37ca-4a5a-b769-e8a3ff187661
fc19f48f-0098-47a0-b0ad-040cf25c7270	f	anonymous_layout_1562691235585	2019-07-09 12:53:55.591	dotcms.org.1	0		\N	\N	\N		5bf7da04-f79c-4a31-8eee-fddc2b157421	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"1"}],"widthPercent":100,"leftOffset":1,"preview":false,"width":12,"left":0}],"identifier":0},{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"1"}],"widthPercent":25,"leftOffset":1,"styleClass":"","preview":false,"width":3,"left":0},{"containers":[{"identifier":"/application/containers/default/","uuid":"2"}],"widthPercent":25,"leftOffset":4,"styleClass":"","preview":false,"width":3,"left":3}],"identifier":0}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	d7b0ebc2-37ca-4a5a-b769-e8a3ff187661
c93c3500-2a0f-4cd6-b5c6-0490b1e014d1	f	anonymous_layout_1562020499754	2019-07-01 18:34:59.79	dotcms.org.1	0		\N	\N	\N		6ffd89b1-3484-4a17-b5b4-e96ecdc6b4f9	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"1"}],"widthPercent":41,"leftOffset":1,"preview":false,"width":5,"left":0},{"containers":[{"identifier":"/application/containers/default/","uuid":"2"}],"widthPercent":58,"leftOffset":6,"styleClass":"","preview":false,"width":7,"left":5}],"identifier":0}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	d7b0ebc2-37ca-4a5a-b769-e8a3ff187661
c3973631-3038-4bdb-b27e-25b8fd82cf24	f	anonymous_layout_1560281276664	2019-06-11 15:27:56.67	dotcms.org.1	0		\N	\N	\N		76534a2a-04cd-4fd7-b891-0a1e61b1a859	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"1"}],"widthPercent":33,"leftOffset":1,"styleClass":"","preview":false,"width":4,"left":0},{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"2"}],"widthPercent":66,"leftOffset":5,"styleClass":"","preview":false,"width":8,"left":4}],"identifier":0}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	d7b0ebc2-37ca-4a5a-b769-e8a3ff187661
50938cdd-6855-4761-9d67-86557093a682	f	anonymous_layout_1559587832876	2019-06-03 14:50:32.921	dotcms.org.1	0		\N	\N	\N		cff6f9a9-d0f3-45c2-9370-dc0457c6bbf0	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"1"}],"widthPercent":100,"leftOffset":1,"styleClass":"","preview":false,"width":12,"left":0}],"identifier":0},{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"2"}],"widthPercent":100,"leftOffset":1,"preview":false,"width":12,"left":0}],"identifier":0}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	d7b0ebc2-37ca-4a5a-b769-e8a3ff187661
704bb3b3-10d7-45d0-a36a-6029838bda85	f	anonymous_layout_1559586338394	2019-06-03 14:25:38.491	dotcms.org.1	0		\N	\N	\N		17dfb289-ee8c-4e88-8cb4-ec036c999174	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"1"}],"widthPercent":100,"leftOffset":1,"preview":false,"width":12,"left":0}],"identifier":0},{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"2"}],"widthPercent":50,"leftOffset":1,"preview":false,"width":6,"left":0},{"containers":[{"identifier":"/application/containers/default/","uuid":"3"}],"widthPercent":50,"leftOffset":7,"styleClass":"","preview":false,"width":6,"left":6}],"identifier":0}]},"sidebar":{"containers":[{"identifier":"b590d738-8bf9-42b0-a8dd-5787a4e20962","uuid":"1"}],"location":"left","width":"medium","widthPercent":30,"preview":false}}	\N	\N	\N	d7b0ebc2-37ca-4a5a-b769-e8a3ff187661
9962d47f-0f4a-436b-92d8-6045efd60396	f	anonymous_layout_1559582538696	2019-06-03 13:22:18.715	dotcms.org.1	0		\N	\N	\N		5ff402db-77c2-499c-a7db-a62d31d86cc4	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"1"}],"widthPercent":58,"leftOffset":1,"preview":false,"width":7,"left":0},{"containers":[{"identifier":"/application/containers/default/","uuid":"1"}],"widthPercent":33,"leftOffset":9,"styleClass":"","preview":false,"width":4,"left":8}],"identifier":0}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	d7b0ebc2-37ca-4a5a-b769-e8a3ff187661
cfca3943-5f2c-4caf-9a6e-874c5db06f3f	f	anonymous_layout_1559582101175	2019-06-03 13:15:01.192	dotcms.org.1	0		\N	\N	\N		22236f46-f887-4c57-ae80-6a929e7bc4c1	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"1"}],"widthPercent":58,"leftOffset":1,"styleClass":"","preview":false,"width":7,"left":0},{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"2"}],"widthPercent":41,"leftOffset":8,"preview":false,"width":5,"left":7}],"identifier":0},{"columns":[{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"3"}],"widthPercent":66,"leftOffset":1,"styleClass":"","preview":false,"width":8,"left":0},{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"4"}],"widthPercent":33,"leftOffset":9,"styleClass":"","preview":false,"width":4,"left":8}],"identifier":0}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	d7b0ebc2-37ca-4a5a-b769-e8a3ff187661
289410c6-9b76-4b48-94c6-f8d04bccc3df	f	anonymous_layout_1558550765432	2019-05-22 14:46:05.455	dotcms.org.1	0		\N	\N	\N		0cb1654b-90e8-4ff5-b8c1-0dcc0508f6ef	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"5a07f889-4536-4956-aa6e-e7967969ec3f","uuid":"1"}],"widthPercent":100,"leftOffset":1,"styleClass":"mb-4","preview":false,"width":12,"left":0}],"identifier":0},{"columns":[{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"1"}],"widthPercent":33,"leftOffset":1,"styleClass":"","preview":false,"width":4,"left":0},{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"2"}],"widthPercent":58,"leftOffset":6,"styleClass":"","preview":false,"width":7,"left":5}],"identifier":0}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	d7b0ebc2-37ca-4a5a-b769-e8a3ff187661
0f73fef5-7269-41f3-9438-9830a457b6a0	f	anonymous_layout_1558542420435	2019-05-22 12:27:00.446	dotcms.org.1	0		\N	\N	\N		76534a2a-04cd-4fd7-b891-0a1e61b1a859	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"1"}],"widthPercent":33,"leftOffset":1,"preview":false,"width":4,"left":0},{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"2"}],"widthPercent":66,"leftOffset":5,"styleClass":"","preview":false,"width":8,"left":4}],"identifier":0}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	d7b0ebc2-37ca-4a5a-b769-e8a3ff187661
92fb0fee-5aa7-409c-87ef-63cb3f3c70f4	f	anonymous_layout_1558100672082	2019-05-17 16:44:33.278	system	0		\N	\N	\N		cff6f9a9-d0f3-45c2-9370-dc0457c6bbf0	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"1"}],"widthPercent":100,"leftOffset":1,"styleClass":"","preview":false,"width":12,"left":0}],"identifier":0},{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"2"}],"widthPercent":66,"leftOffset":3,"preview":false,"width":8,"left":2}],"identifier":0},{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"3"}],"widthPercent":25,"leftOffset":1,"styleClass":"","preview":false,"width":3,"left":0},{"containers":[{"identifier":"/application/containers/default/","uuid":"4"}],"widthPercent":25,"leftOffset":4,"styleClass":"","preview":false,"width":3,"left":3},{"containers":[{"identifier":"/application/containers/default/","uuid":"5"}],"widthPercent":25,"leftOffset":7,"styleClass":"","preview":false,"width":3,"left":6},{"containers":[{"identifier":"/application/containers/default/","uuid":"6"}],"widthPercent":25,"leftOffset":10,"styleClass":"","preview":false,"width":3,"left":9}],"identifier":0}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	d7b0ebc2-37ca-4a5a-b769-e8a3ff187661
f4240c47-913e-4c1a-8e54-e80eb1e7961d	f	anonymous_layout_1558096947715	2019-05-17 16:44:33.082	system	0		\N	\N	\N		5a322949-aca5-4518-9920-fbd4de84a82d	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"1"}],"widthPercent":100,"leftOffset":1,"preview":false,"width":12,"left":0}],"identifier":0}]},"sidebar":{"containers":[{"identifier":"b590d738-8bf9-42b0-a8dd-5787a4e20962","uuid":"1"}],"location":"right","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	d7b0ebc2-37ca-4a5a-b769-e8a3ff187661
10013c6a-ec0a-4b54-b406-c75d1c3cd2f3	f	anonymous_layout_1558096930426	2019-05-17 16:44:33.029	system	0		\N	\N	\N		2d0fcd52-e3ca-4f33-91e8-baff8db7b88e	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"1"}],"widthPercent":100,"leftOffset":1,"preview":false,"width":12,"left":0}],"identifier":0}]},"sidebar":{"containers":[{"identifier":"b590d738-8bf9-42b0-a8dd-5787a4e20962","uuid":"1"}],"location":"right","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	d7b0ebc2-37ca-4a5a-b769-e8a3ff187661
2d586171-ca0e-439d-8cec-0203cbecac07	f	anonymous_layout_1555597046917	2019-05-17 16:44:33.089	dotcms.org.1	0		\N	\N	\N		5bf7da04-f79c-4a31-8eee-fddc2b157421	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"1"}],"widthPercent":100,"leftOffset":1,"preview":false,"width":12,"left":0}],"identifier":0}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	d7b0ebc2-37ca-4a5a-b769-e8a3ff187661
3048660e-c036-47b8-9bde-6ef96ff609a7	f	anonymous_layout_1555500276535	2019-05-17 16:44:33.139	dotcms.org.1	0		\N	\N	\N		7ca937a7-a2b0-4da6-b8f7-a26dffda3827	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"1"}],"widthPercent":100,"leftOffset":1,"preview":false,"width":12,"left":0}],"identifier":0}]},"sidebar":{"containers":[{"identifier":"b590d738-8bf9-42b0-a8dd-5787a4e20962","uuid":"1"}],"location":"right","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	d7b0ebc2-37ca-4a5a-b769-e8a3ff187661
76fdb150-ceae-4033-8f39-bb97a5332fc5	f	anonymous_layout_1555500138356	2019-05-17 16:44:33.202	dotcms.org.1	0		\N	\N	\N		d03bcbfe-b67b-482c-ba1d-24fb5f6c5dc2	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"1"}],"widthPercent":100,"leftOffset":1,"preview":false,"width":12,"left":0}],"identifier":0}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	d7b0ebc2-37ca-4a5a-b769-e8a3ff187661
30ced9f0-be4c-4a3e-9dfc-00dd782ec9d1	f	anonymous_layout_1555455913239	2019-05-17 16:44:33.044	dotcms.org.1	0		\N	\N	\N		46bf0614-73ac-48c5-a59f-fc5b883eabe3	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"1"}],"widthPercent":100,"leftOffset":1,"preview":false,"width":12,"left":0}],"identifier":0}]},"sidebar":{"containers":[{"identifier":"b590d738-8bf9-42b0-a8dd-5787a4e20962","uuid":"1"}],"location":"right","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	d7b0ebc2-37ca-4a5a-b769-e8a3ff187661
86b9c834-bb74-4e19-8743-cf23e166f711	f	anonymous_layout_1555455901547	2019-05-17 16:44:33.23	dotcms.org.1	0		\N	\N	\N		dee9deb8-6ed9-45d8-80d4-efc4614d2113	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"1"}],"widthPercent":100,"leftOffset":1,"preview":false,"width":12,"left":0}],"identifier":0}]},"sidebar":{"containers":[{"identifier":"b590d738-8bf9-42b0-a8dd-5787a4e20962","uuid":"1"}],"location":"right","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	d7b0ebc2-37ca-4a5a-b769-e8a3ff187661
969ca173-fbdd-4e26-8f2e-1d9ba8521bdc	f	anonymous_layout_1555455878450	2019-05-17 16:44:33.175	dotcms.org.1	0		\N	\N	\N		c4500d42-30da-413d-aca9-7b56f844a055	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"1"}],"widthPercent":100,"leftOffset":1,"preview":false,"width":12,"left":0}],"identifier":0},{"columns":[{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"2"}],"widthPercent":100,"leftOffset":1,"styleClass":"","preview":false,"width":12,"left":0}],"identifier":0}]},"sidebar":{"containers":[{"identifier":"b590d738-8bf9-42b0-a8dd-5787a4e20962","uuid":"1"}],"location":"right","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	d7b0ebc2-37ca-4a5a-b769-e8a3ff187661
0546d6b9-63bd-466e-bc05-c467fd7e2d61	f	anonymous_layout_1555455481477	2019-05-17 16:44:33.099	dotcms.org.1	0		\N	\N	\N		5ff402db-77c2-499c-a7db-a62d31d86cc4	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"1"}],"widthPercent":58,"leftOffset":1,"preview":false,"width":7,"left":0},{"containers":[{"identifier":"/application/containers/default/","uuid":"1"}],"widthPercent":33,"leftOffset":9,"styleClass":"","preview":false,"width":4,"left":8}],"identifier":0}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	d7b0ebc2-37ca-4a5a-b769-e8a3ff187661
cc5ef9c6-737e-41a6-992f-8cb397248266	f	anonymous_layout_1555455189325	2019-05-17 16:44:33.251	dotcms.org.1	0		\N	\N	\N		2d0683c7-a8ad-406d-a4d5-ec47899a902b	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"1"}],"widthPercent":58,"leftOffset":1,"preview":false,"width":7,"left":0},{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"2"}],"widthPercent":41,"leftOffset":8,"preview":false,"width":5,"left":7}],"identifier":0},{"columns":[{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"3"}],"widthPercent":100,"leftOffset":1,"preview":false,"width":12,"left":0}],"identifier":0}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	d7b0ebc2-37ca-4a5a-b769-e8a3ff187661
97aad934-5d1e-4132-a61c-46f33d1b318d	f	anonymous_layout_1555455055449	2019-05-17 16:44:33.166	dotcms.org.1	0		\N	\N	\N		b0457d83-b3aa-46d2-a6f8-cbc553780f33	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"1"}],"widthPercent":100,"leftOffset":1,"preview":false,"width":12,"left":0}],"identifier":0},{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"2"}],"widthPercent":50,"leftOffset":1,"preview":false,"width":6,"left":0},{"containers":[{"identifier":"/application/containers/default/","uuid":"3"}],"widthPercent":50,"leftOffset":7,"preview":false,"width":6,"left":6}],"identifier":0},{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"4"}],"widthPercent":66,"leftOffset":3,"preview":false,"width":8,"left":2}],"identifier":0},{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"5"}],"widthPercent":100,"leftOffset":1,"preview":false,"width":12,"left":0}],"identifier":0}]},"sidebar":{"containers":[{"identifier":"b590d738-8bf9-42b0-a8dd-5787a4e20962","uuid":"1"}],"location":"left","width":"medium","widthPercent":30,"preview":false}}	\N	\N	\N	d7b0ebc2-37ca-4a5a-b769-e8a3ff187661
45d04c50-df12-4f29-93dd-4b6721870f4e	f	anonymous_layout_1555453912975	2019-05-17 16:44:33.213	dotcms.org.1	0		\N	\N	\N		d0d0aa0f-8aba-416c-8951-f3e8fe9f20cc	t	{"header":false,"footer":false,"body":{"rows":[{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"1"}],"widthPercent":66,"leftOffset":3,"preview":false,"width":8,"left":2}],"identifier":0}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	d7b0ebc2-37ca-4a5a-b769-e8a3ff187661
06bc889b-d859-4d90-87a8-9eaa41cc6295	f	anonymous_layout_1555433568766	2019-05-17 16:44:33.289	dotcms.org.1	0		\N	\N	\N		f58cf618-df78-481c-b2ce-450bac89273a	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"1"}],"widthPercent":75,"leftOffset":1,"preview":false,"width":9,"left":0},{"containers":[{"identifier":"b590d738-8bf9-42b0-a8dd-5787a4e20962","uuid":"1"}],"widthPercent":25,"leftOffset":10,"styleClass":"","preview":false,"width":3,"left":9}],"identifier":0}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	d7b0ebc2-37ca-4a5a-b769-e8a3ff187661
0702913b-f954-469f-a05f-5d3fc616daf2	f	anonymous_layout_1555431010633	2019-05-17 16:44:33.222	dotcms.org.1	0		\N	\N	\N		dc557d44-d90e-4a3c-ba8f-4cc9ee164fda	t	{"header":false,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"1"}],"widthPercent":100,"leftOffset":1,"preview":false,"width":12,"left":0}],"identifier":0},{"columns":[{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"2"}],"widthPercent":100,"leftOffset":1,"styleClass":"","preview":false,"width":12,"left":0}],"identifier":0}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	d7b0ebc2-37ca-4a5a-b769-e8a3ff187661
abe89660-1b0b-48c9-9023-826267b07876	f	anonymous_layout_1555348454466 - 1	2019-05-17 16:44:33.262	system	0	anonymous_layout_1555348454466 - 1	\N	\N	\N		5227bb4e-7b53-4777-af63-da789c40404d	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"1"}],"widthPercent":100,"leftOffset":1,"preview":false,"width":12,"left":0}],"identifier":0},{"columns":[{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"2"}],"widthPercent":100,"leftOffset":1,"styleClass":"","preview":false,"width":12,"left":0}],"identifier":0}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	d7b0ebc2-37ca-4a5a-b769-e8a3ff187661
6c764cc6-4e3d-4eac-96cf-a3f403c93e8c	f	anonymous_layout_1555010147644	2019-05-17 16:44:33.073	dotcms.org.1	0		\N	\N	\N		591cc010-2cf8-4da3-b75d-53dee0107062	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"1"}],"widthPercent":100,"leftOffset":1,"preview":false,"width":12,"left":0}],"styleClass":"test","identifier":0}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	d7b0ebc2-37ca-4a5a-b769-e8a3ff187661
0934f429-d611-4c35-b13c-8c49ac2064e6	f	anonymous_layout_1555006209831	2019-04-11 14:10:09.846	dotcms.org.1	0		\N	\N	\N		1f26789c-c4a9-4ceb-835b-cecdcead54ee	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"1"}],"widthPercent":100,"leftOffset":1,"preview":false,"width":12,"left":0}],"identifier":0}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	d7b0ebc2-37ca-4a5a-b769-e8a3ff187661
5c331799-df72-4780-bfa1-56425b0854fe	f	anonymous_layout_1554999440345	2019-04-11 12:17:20.364	dotcms.org.1	0		\N	\N	\N		0bbbb312-52f7-4993-8af1-a87a9ea5ef2b	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"1"}],"widthPercent":66,"leftOffset":1,"preview":false,"width":8,"left":0},{"containers":[{"identifier":"/application/containers/default/","uuid":"2"}],"widthPercent":25,"leftOffset":10,"preview":false,"width":3,"left":9}],"identifier":0}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	d7b0ebc2-37ca-4a5a-b769-e8a3ff187661
45c44f30-c90a-4deb-9fa7-ef270aa09c69	f	anonymous_layout_1554998203616	2019-04-11 11:56:43.652	dotcms.org.1	0		\N	\N	\N		9ce3e0fd-7578-421b-8241-59f6ed3adbd8	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"1"}],"widthPercent":100,"leftOffset":1,"preview":false,"width":12,"left":0}],"identifier":0},{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"2"}],"widthPercent":83,"leftOffset":2,"preview":false,"width":10,"left":1}],"identifier":0},{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"3"}],"widthPercent":50,"leftOffset":1,"preview":false,"width":6,"left":0},{"containers":[{"identifier":"/application/containers/default/","uuid":"4"}],"widthPercent":50,"leftOffset":7,"preview":false,"width":6,"left":6}],"identifier":0},{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"5"}],"widthPercent":100,"leftOffset":1,"preview":false,"width":12,"left":0}],"identifier":0}]},"sidebar":{"containers":[{"identifier":"b590d738-8bf9-42b0-a8dd-5787a4e20962","uuid":"1"}],"location":"left","width":"medium","widthPercent":30,"preview":false}}	\N	\N	\N	d7b0ebc2-37ca-4a5a-b769-e8a3ff187661
757334b2-1690-4b68-8686-1ab99dbc7c17	f	anonymous_layout_1554997966323	2019-04-11 11:52:46.34	dotcms.org.1	0		\N	\N	\N		f58f3fd8-7808-4074-b520-8edb531521e2	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"/application/containers/default/","uuid":"1"}],"widthPercent":100,"leftOffset":1,"preview":false,"width":12,"left":0}],"identifier":0}]},"sidebar":{"containers":[{"identifier":"b590d738-8bf9-42b0-a8dd-5787a4e20962","uuid":"1"}],"location":"left","width":"medium","widthPercent":30,"preview":false}}	\N	\N	\N	d7b0ebc2-37ca-4a5a-b769-e8a3ff187661
e1785c86-0096-4e1e-a799-a2cb273c9a29	f	anonymous_layout_1544643011341	2018-12-12 14:30:11.387	dotcms.org.1	0		\N	\N	\N		c41cf5a6-3312-4e3b-b419-0f7d972f3305	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"1"}],"widthPercent":100,"leftOffset":1,"preview":false,"width":12,"left":0}],"identifier":0},{"columns":[{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"2"}],"widthPercent":33,"leftOffset":1,"preview":false,"width":4,"left":0},{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"3"}],"widthPercent":33,"leftOffset":5,"preview":false,"width":4,"left":4},{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"4"}],"widthPercent":33,"leftOffset":9,"preview":false,"width":4,"left":8}],"identifier":0},{"columns":[{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"5"}],"widthPercent":33,"leftOffset":1,"preview":false,"width":4,"left":0},{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"6"}],"widthPercent":33,"leftOffset":5,"preview":false,"width":4,"left":4},{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"7"}],"widthPercent":33,"leftOffset":9,"preview":false,"width":4,"left":8}],"identifier":0},{"columns":[{"containers":[{"identifier":"5a07f889-4536-4956-aa6e-e7967969ec3f","uuid":"1"}],"widthPercent":100,"leftOffset":1,"preview":false,"width":12,"left":0}],"identifier":0}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	d7b0ebc2-37ca-4a5a-b769-e8a3ff187661
398300f4-1394-4514-9ad4-8809680b92a4	f	anonymous_layout_1541439952336	2018-11-05 12:45:52.36	dotcms.org.1	0		\N	\N	\N		968b8147-92ba-458d-9fe1-941d9f7c0415	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"1"}],"widthPercent":66,"leftOffset":1,"preview":false,"width":8,"left":0},{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"2"}],"widthPercent":33,"leftOffset":9,"preview":false,"width":4,"left":8}],"identifier":0}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	d7b0ebc2-37ca-4a5a-b769-e8a3ff187661
ed0c3959-bfb2-4a8e-927a-17c4d03c9261	f	anonymous_layout_1541174236655	2018-11-02 11:57:16.697	dotcms.org.1	0		\N	\N	\N		6828d30e-b9ec-48c7-b96c-81ef01a0a3b1	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"1"}],"widthPercent":66,"leftOffset":1,"preview":false,"width":8,"left":0},{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"2"}],"widthPercent":33,"leftOffset":9,"preview":false,"width":4,"left":8}],"identifier":0}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	d7b0ebc2-37ca-4a5a-b769-e8a3ff187661
786c0357-ea7e-4c9e-8468-d045424bbab5	f	anonymous_layout_1540475262507	2018-10-25 09:47:42.512	dotcms.org.1	0		\N	\N	\N		1344e901-59ce-4d2d-96ae-90adcf1a5092	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"1"}],"widthPercent":100,"leftOffset":1,"preview":false,"width":12,"left":0}],"identifier":0}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	d7b0ebc2-37ca-4a5a-b769-e8a3ff187661
5521a1d4-ccf4-431e-a62d-57c3857ba9df	f	anonymous_layout_1537989644811	2018-09-26 15:20:44.884	dotcms.org.1	0		\N	\N	\N		2c69bb81-0f25-4a05-8d10-918b5b40a24b	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"1"}],"widthPercent":66,"leftOffset":3,"preview":false,"width":8,"left":2}],"identifier":0},{"columns":[{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"2"}],"widthPercent":25,"leftOffset":1,"preview":false,"width":3,"left":0},{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"3"}],"widthPercent":25,"leftOffset":4,"preview":false,"width":3,"left":3},{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"4"}],"widthPercent":25,"leftOffset":7,"preview":false,"width":3,"left":6},{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"5"}],"widthPercent":25,"leftOffset":10,"preview":false,"width":3,"left":9}],"identifier":0}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	d7b0ebc2-37ca-4a5a-b769-e8a3ff187661
78bde330-97af-49f5-a62a-46a624f4a6b1	f	anonymous_layout_1537892350250	2018-09-25 12:19:10.255	dotcms.org.1	0		\N	\N	\N		339be8a8-d6aa-4196-b20e-a0ebc5c82037	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"1"}],"widthPercent":100,"leftOffset":1,"preview":false,"width":12,"left":0}],"identifier":0}]},"sidebar":{"containers":[{"identifier":"b590d738-8bf9-42b0-a8dd-5787a4e20962","uuid":"1"}],"location":"left","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	d7b0ebc2-37ca-4a5a-b769-e8a3ff187661
fe871bb5-be92-48d1-90d6-83d299444c77	f	anonymous_layout_1537886693058	2018-09-25 10:44:53.063	dotcms.org.1	0		\N	\N	\N		052e6ccf-408c-43b7-a9d8-6a9505561ae2	t	{"header":false,"footer":false,"body":{"rows":[{"columns":[{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"1"}],"widthPercent":100,"leftOffset":1,"preview":false,"width":12,"left":0}],"identifier":0}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	79479e0e-87d0-4260-9c12-3f05e303adcc
5b12f27b-6a9b-4179-9fb8-7f6032303877	f	anonymous_layout_1537844308610	2018-09-24 22:58:28.632	dotcms.org.1	0		\N	\N	\N		aed0ee71-a4b8-4afe-8a14-339f79ec5a6f	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"1"}],"widthPercent":25,"leftOffset":1,"preview":false,"width":3,"left":0},{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"2"}],"widthPercent":75,"leftOffset":4,"preview":false,"width":9,"left":3}],"identifier":0}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	79479e0e-87d0-4260-9c12-3f05e303adcc
2b58d456-e891-4433-b9c2-f0086669ae0a	f	anonymous_layout_1537836003471	2018-09-24 20:40:03.48	dotcms.org.1	0		\N	\N	\N		53fd322d-7f6d-4796-ba88-3880a256f13c	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"1"}],"widthPercent":25,"leftOffset":1,"preview":false,"width":3,"left":0},{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"2"}],"widthPercent":75,"leftOffset":4,"preview":false,"width":9,"left":3}],"identifier":0}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	79479e0e-87d0-4260-9c12-3f05e303adcc
264b9596-95dc-41e2-a3ab-ce8a94542055	f	anonymous_layout_1537805809600	2018-09-24 12:16:49.627	dotcms.org.1	0		\N	\N	\N		ea37dc2f-328b-452f-b05b-265a8a48382d	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"1"}],"widthPercent":75,"leftOffset":1,"preview":false,"width":9,"left":0},{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"2"}],"widthPercent":25,"leftOffset":10,"preview":false,"width":3,"left":9}],"identifier":0}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	79479e0e-87d0-4260-9c12-3f05e303adcc
f0216d57-8d4c-4863-a3e8-9ef3ff168f1f	f	anonymous_layout_1537794349150	2018-09-24 09:05:49.179	dotcms.org.1	0		\N	\N	\N		9ac7acb5-cef0-48fd-8cf4-963059442f2c	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"1"}],"widthPercent":100,"leftOffset":1,"preview":false,"width":12,"left":0}],"identifier":0}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	79479e0e-87d0-4260-9c12-3f05e303adcc
f2b7c8d8-a7c1-4334-9c0d-01ea70822baf	f	anonymous_layout_1537548456147	2018-09-21 12:47:36.171	dotcms.org.1	0		\N	\N	\N		8257a204-4cc2-48d6-b73f-189c34aedc2c	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"1"}],"widthPercent":100,"leftOffset":1,"preview":false,"width":12,"left":0}],"identifier":0},{"columns":[{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"2"}],"widthPercent":58,"leftOffset":1,"preview":false,"width":7,"left":0},{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"3"}],"widthPercent":41,"leftOffset":8,"preview":false,"width":5,"left":7}],"identifier":0}]},"sidebar":{"containers":[{"identifier":"b590d738-8bf9-42b0-a8dd-5787a4e20962","uuid":"1"}],"location":"left","width":"medium","widthPercent":30,"preview":false}}	\N	\N	\N	79479e0e-87d0-4260-9c12-3f05e303adcc
354e2ec6-aba0-4c70-be8b-4136a44e04dc	f	anonymous_layout_1537291691787	2018-09-18 13:28:11.811	dotcms.org.1	0		\N	\N	\N		38bba30b-47d1-4c9c-a6d3-63b6e30b529a	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"1"}],"widthPercent":100,"leftOffset":1,"preview":false,"width":12,"left":0}],"identifier":0},{"columns":[{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"2"}],"widthPercent":50,"leftOffset":1,"preview":false,"width":6,"left":0},{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"3"}],"widthPercent":41,"leftOffset":8,"preview":false,"width":5,"left":7}],"identifier":0}]},"sidebar":{"containers":[{"identifier":"b590d738-8bf9-42b0-a8dd-5787a4e20962","uuid":"1"}],"location":"left","width":"medium","widthPercent":30,"preview":false}}	\N	\N	\N	79479e0e-87d0-4260-9c12-3f05e303adcc
2e68de1c-51d9-4cb1-86e1-bdfb87a28239	f	anonymous_layout_1537287749393	2018-09-18 12:22:29.431	dotcms.org.1	0		\N	\N	\N		5d585f86-15ec-42a4-9a1a-87e57959cfbf	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"2"}],"widthPercent":100,"leftOffset":1,"preview":false,"width":12,"left":0}],"identifier":0}]},"sidebar":{"containers":[{"identifier":"b590d738-8bf9-42b0-a8dd-5787a4e20962","uuid":"1"},{"identifier":"c17c0855-93fd-4349-a2a2-6982e9d559e1","uuid":"1"}],"location":"left","width":"medium","widthPercent":30,"preview":false}}	\N	\N	\N	79479e0e-87d0-4260-9c12-3f05e303adcc
a090b2b0-0753-4771-934e-660b0368113c	f	anonymous_layout_1532459868249	2018-07-24 15:17:48.275	dotcms.org.1	0		\N	\N	\N		96e19b30-4f82-4a40-82ed-e8640962be93	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"56bd55ea-b04b-480d-9e37-5d6f9217dcc3","uuid":"1"}],"widthPercent":100,"leftOffset":1,"preview":false,"width":12,"left":0}],"identifier":0},{"columns":[{"containers":[{"identifier":"56bd55ea-b04b-480d-9e37-5d6f9217dcc3","uuid":"2"}],"widthPercent":100,"leftOffset":1,"preview":false,"width":12,"left":0}],"identifier":0}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	b0c4b5e2-a7f6-43c0-a72f-5fef2bfcac23
f5879d20-abff-479d-aaa4-b417a3725998	f	anonymous_layout_1532459354731	2018-07-24 15:09:14.759	dotcms.org.1	0		\N	\N	\N		96e19b30-4f82-4a40-82ed-e8640962be93	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"56bd55ea-b04b-480d-9e37-5d6f9217dcc3","uuid":"1"}],"widthPercent":100,"leftOffset":1,"preview":false,"width":12,"left":0}],"identifier":0},{"columns":[{"containers":[{"identifier":"56bd55ea-b04b-480d-9e37-5d6f9217dcc3","uuid":"2"}],"widthPercent":100,"leftOffset":1,"preview":false,"width":12,"left":0}],"identifier":0}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	b0c4b5e2-a7f6-43c0-a72f-5fef2bfcac23
adba605c-4370-4db3-962e-b91ec4604e99	f	anonymous_layout_1531933597381	2018-07-18 13:06:37.399	dotcms.org.1	0		\N	\N	\N		5389e6a5-ee91-4164-b6ad-cc4f695f1d84	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"56bd55ea-b04b-480d-9e37-5d6f9217dcc3","uuid":"1"}],"widthPercent":100,"leftOffset":1,"preview":false,"width":12,"left":0}],"identifier":0},{"columns":[{"containers":[{"identifier":"56bd55ea-b04b-480d-9e37-5d6f9217dcc3","uuid":"2"}],"widthPercent":66,"leftOffset":1,"preview":false,"width":8,"left":0},{"containers":[{"identifier":"fc193c82-8c32-4abe-ba8a-49522328c93e","uuid":"1"}],"widthPercent":33,"leftOffset":9,"preview":false,"width":4,"left":8}],"identifier":0}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	b0c4b5e2-a7f6-43c0-a72f-5fef2bfcac23
367a8fa6-327d-4858-b26c-e095036dee88	f	anonymous_layout_1528922390015	2018-06-13 16:39:50.02	dotcms.org.1	0		\N	\N	\N		4341f0fd-a456-4d77-83da-a5cd7248624d	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"56bd55ea-b04b-480d-9e37-5d6f9217dcc3","uuid":"1"}],"widthPercent":66,"leftOffset":1,"preview":false,"width":8,"left":0},{"containers":[{"identifier":"5363c6c6-5ba0-4946-b7af-cf875188ac2e","uuid":"1"}],"widthPercent":33,"leftOffset":9,"preview":false,"width":4,"left":8}],"identifier":0}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	79479e0e-87d0-4260-9c12-3f05e303adcc
84d3cfd1-b476-4bd9-a775-7c0c421c3937	f	anonymous_layout_1528919573185	2018-06-13 15:52:53.192	dotcms.org.1	0		\N	\N	\N		a55a982f-2b8f-4672-8a5a-f4560a42ec1d	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"56bd55ea-b04b-480d-9e37-5d6f9217dcc3","uuid":"1"}],"widthPercent":33,"leftOffset":1,"preview":false,"width":4,"left":0},{"containers":[{"identifier":"56bd55ea-b04b-480d-9e37-5d6f9217dcc3","uuid":"2"}],"widthPercent":50,"leftOffset":5,"preview":false,"width":6,"left":4},{"containers":[{"identifier":"56bd55ea-b04b-480d-9e37-5d6f9217dcc3","uuid":"3"}],"widthPercent":16,"leftOffset":11,"preview":false,"width":2,"left":10}],"identifier":0}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	79479e0e-87d0-4260-9c12-3f05e303adcc
ab656a52-cd55-450b-818f-a33ac3996297	f	anonymous_layout_1528918253047	2018-06-13 15:30:53.053	dotcms.org.1	0		\N	\N	\N		d1ec7b30-8e9e-4b3e-b075-9cd9557fee8b	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"56bd55ea-b04b-480d-9e37-5d6f9217dcc3","uuid":"1"}],"widthPercent":100,"leftOffset":1,"preview":false,"width":12,"left":0}],"identifier":0},{"columns":[{"containers":[{"identifier":"3f0255e8-b45d-46ea-8bb7-eb6597db4c1e","uuid":"1"}],"widthPercent":25,"leftOffset":1,"preview":false,"width":3,"left":0},{"containers":[{"identifier":"3f0255e8-b45d-46ea-8bb7-eb6597db4c1e","uuid":"2"}],"widthPercent":25,"leftOffset":4,"preview":false,"width":3,"left":3},{"containers":[{"identifier":"3f0255e8-b45d-46ea-8bb7-eb6597db4c1e","uuid":"3"}],"widthPercent":25,"leftOffset":7,"preview":false,"width":3,"left":6},{"containers":[{"identifier":"3f0255e8-b45d-46ea-8bb7-eb6597db4c1e","uuid":"4"}],"widthPercent":25,"leftOffset":10,"preview":false,"width":3,"left":9}],"identifier":0},{"columns":[{"containers":[{"identifier":"56bd55ea-b04b-480d-9e37-5d6f9217dcc3","uuid":"2"}],"widthPercent":66,"leftOffset":1,"preview":false,"width":8,"left":0},{"containers":[{"identifier":"5363c6c6-5ba0-4946-b7af-cf875188ac2e","uuid":"1"}],"widthPercent":33,"leftOffset":9,"preview":false,"width":4,"left":8}],"identifier":0}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	79479e0e-87d0-4260-9c12-3f05e303adcc
a9b894fc-48dc-485b-b2d9-587956515e4c	f	anonymous_layout_1523036632378	2018-04-06 13:43:52.381	dotcms.org.1	0		\N	\N	\N		4bb72d3b-e572-4910-8fc2-d725279adeb5	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"56bd55ea-b04b-480d-9e37-5d6f9217dcc3","uuid":"LEGACY_RELATION_TYPE"}],"widthPercent":66,"leftOffset":1,"preview":false,"width":8,"left":0},{"containers":[{"identifier":"5363c6c6-5ba0-4946-b7af-cf875188ac2e","uuid":"LEGACY_RELATION_TYPE"}],"widthPercent":33,"leftOffset":9,"preview":false,"width":4,"left":8}],"identifier":0}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":0,"preview":false}}	\N	\N	\N	79479e0e-87d0-4260-9c12-3f05e303adcc
4c7ce396-0685-4b66-bcfc-6561dd7dad33	f	anonymous_layout_1520261408317	2018-03-05 09:51:43.404	dotcms.org.1	0		\N	\N	\N		86a1e1fe-c026-49f7-91c9-3fb5a77e0172	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"56bd55ea-b04b-480d-9e37-5d6f9217dcc3","uuid":"LEGACY_RELATION_TYPE"}],"widthPercent":66,"leftOffset":1,"preview":false,"width":8,"left":0},{"containers":[{"identifier":"5363c6c6-5ba0-4946-b7af-cf875188ac2e","uuid":"LEGACY_RELATION_TYPE"}],"widthPercent":33,"leftOffset":9,"preview":false,"width":4,"left":8}],"identifier":0},{"columns":[{"containers":[],"widthPercent":50,"leftOffset":1,"preview":false,"width":6,"left":0},{"containers":[],"widthPercent":50,"leftOffset":7,"preview":false,"width":6,"left":6}],"identifier":0}]},"sidebar":{"location":"","width":"small","widthPercent":0,"preview":false}}	\N	\N	\N	79479e0e-87d0-4260-9c12-3f05e303adcc
59e3bb7c-abf0-41ea-9b22-000c862b8d13	f	anonymous_layout_1564529836499	2019-07-30 19:37:16.505	dotcms.org.2808	0		\N	\N	\N		ed39ed50-0118-4ac2-b047-a8c0960dbd48	t	{"header":true,"footer":true,"body":{"rows":[{"columns":[{"containers":[{"identifier":"854ad819-8381-434d-a70f-6e2330985ea4","uuid":"1"}],"widthPercent":100,"leftOffset":1,"preview":false,"width":12,"left":0}],"styleClass":""}]},"sidebar":{"containers":[],"location":"","width":"small","widthPercent":20,"preview":false}}	\N	\N	\N	d7b0ebc2-37ca-4a5a-b769-e8a3ff187661
\.


--
-- Data for Name: template_containers; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.template_containers (id, template_id, container_id) FROM stdin;
\.


--
-- Data for Name: template_version_info; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.template_version_info (identifier, working_inode, live_inode, deleted, locked_by, locked_on, version_ts) FROM stdin;
040d7fdf-fb31-4a92-867b-a67bccdfca29	54b4cf8d-0538-4862-a392-e544bb865c38	54b4cf8d-0538-4862-a392-e544bb865c38	f	\N	2019-07-10 10:54:26.341	2019-08-21 09:36:56.315
052e6ccf-408c-43b7-a9d8-6a9505561ae2	fe871bb5-be92-48d1-90d6-83d299444c77	fe871bb5-be92-48d1-90d6-83d299444c77	f	\N	2018-09-25 10:44:53.066	2019-05-17 16:44:33.299
0b280c00-834f-4721-a48e-2f4df97607ea	0856a795-cba1-488a-ba13-f10f2983a42d	0856a795-cba1-488a-ba13-f10f2983a42d	f	\N	2019-08-28 11:48:15.54	2019-09-23 17:09:41.837
0bbbb312-52f7-4993-8af1-a87a9ea5ef2b	5c331799-df72-4780-bfa1-56425b0854fe	5c331799-df72-4780-bfa1-56425b0854fe	f	\N	2018-11-01 13:15:14.908	2019-05-17 16:44:33.302
0c556e37-99e0-4458-a2cd-d42cc7a11045	cfda9246-cce3-4313-8cc3-2080d1935cf9	cfda9246-cce3-4313-8cc3-2080d1935cf9	f	\N	2020-01-10 15:21:42.565	2020-01-22 13:08:24.398
0cb1654b-90e8-4ff5-b8c1-0dcc0508f6ef	289410c6-9b76-4b48-94c6-f8d04bccc3df	\N	f	\N	2019-05-22 14:34:41.919	2019-05-22 14:46:05.458
1344e901-59ce-4d2d-96ae-90adcf1a5092	786c0357-ea7e-4c9e-8468-d045424bbab5	786c0357-ea7e-4c9e-8468-d045424bbab5	f	\N	2018-10-25 09:36:22.468	2019-05-17 16:44:33.304
17dfb289-ee8c-4e88-8cb4-ec036c999174	704bb3b3-10d7-45d0-a36a-6029838bda85	704bb3b3-10d7-45d0-a36a-6029838bda85	f	\N	2018-11-02 13:47:50.335	2019-06-03 14:28:21.842
1f26789c-c4a9-4ceb-835b-cecdcead54ee	0934f429-d611-4c35-b13c-8c49ac2064e6	0934f429-d611-4c35-b13c-8c49ac2064e6	f	\N	2019-04-11 14:10:09.848	2019-05-17 16:44:33.311
22236f46-f887-4c57-ae80-6a929e7bc4c1	cfca3943-5f2c-4caf-9a6e-874c5db06f3f	cfca3943-5f2c-4caf-9a6e-874c5db06f3f	f	\N	2019-06-03 13:13:20.814	2019-06-03 13:15:12.493
2b457e67-9c94-4cb3-8d1b-422fbe4fd5a0	b7046ed2-ccf0-45c6-8819-d4c3994ce765	b7046ed2-ccf0-45c6-8819-d4c3994ce765	f	\N	2018-11-01 14:57:23.97	2019-07-18 11:44:37.754
2c69bb81-0f25-4a05-8d10-918b5b40a24b	5521a1d4-ccf4-431e-a62d-57c3857ba9df	5521a1d4-ccf4-431e-a62d-57c3857ba9df	f	\N	2018-09-14 17:46:43.303	2019-05-17 16:44:33.315
2d0683c7-a8ad-406d-a4d5-ec47899a902b	cc5ef9c6-737e-41a6-992f-8cb397248266	cc5ef9c6-737e-41a6-992f-8cb397248266	f	\N	2018-11-27 14:42:07.275	2019-05-17 16:45:57.788
2d0fcd52-e3ca-4f33-91e8-baff8db7b88e	10013c6a-ec0a-4b54-b406-c75d1c3cd2f3	10013c6a-ec0a-4b54-b406-c75d1c3cd2f3	f	\N	2019-05-17 08:42:10.435	2019-05-17 16:44:33.319
339be8a8-d6aa-4196-b20e-a0ebc5c82037	78bde330-97af-49f5-a62a-46a624f4a6b1	\N	f	\N	2018-09-25 12:19:10.257	2019-05-17 16:44:33.411
35fe888d-1555-43ad-b155-080dd7d9b9cf	98d027b1-189d-41e2-adba-9f873b593e86	98d027b1-189d-41e2-adba-9f873b593e86	f	\N	2019-07-16 17:26:49.701	2019-07-16 17:26:54.402
3826636b-cc3a-46b2-97c5-ce6bdb377fcb	80d27245-8e05-42b4-955b-c48811b8b24e	80d27245-8e05-42b4-955b-c48811b8b24e	f	\N	2019-07-09 16:47:48.263	2019-07-09 16:47:55.783
38bba30b-47d1-4c9c-a6d3-63b6e30b529a	354e2ec6-aba0-4c70-be8b-4136a44e04dc	354e2ec6-aba0-4c70-be8b-4136a44e04dc	f	\N	2018-09-18 13:24:50.661	2019-05-17 16:44:33.322
4341f0fd-a456-4d77-83da-a5cd7248624d	367a8fa6-327d-4858-b26c-e095036dee88	\N	f	\N	2018-06-13 16:26:35.71	2019-05-17 16:44:33.413
46bf0614-73ac-48c5-a59f-fc5b883eabe3	30ced9f0-be4c-4a3e-9dfc-00dd782ec9d1	30ced9f0-be4c-4a3e-9dfc-00dd782ec9d1	f	\N	2019-04-16 18:09:27.692	2019-05-17 16:44:33.324
4bb72d3b-e572-4910-8fc2-d725279adeb5	a9b894fc-48dc-485b-b2d9-587956515e4c	a9b894fc-48dc-485b-b2d9-587956515e4c	f	\N	2018-04-06 13:11:20.214	2019-05-17 16:44:33.327
50042108-38ec-48ba-be91-7f4368c8630f	9164f879-b4bb-46de-a306-4cdd7952253d	9164f879-b4bb-46de-a306-4cdd7952253d	f	\N	2019-07-25 14:42:31.561	2019-07-25 14:42:39.911
5227bb4e-7b53-4777-af63-da789c40404d	abe89660-1b0b-48c9-9023-826267b07876	\N	f	\N	2019-04-15 14:19:56.756	2019-05-17 16:44:33.418
5389e6a5-ee91-4164-b6ad-cc4f695f1d84	adba605c-4370-4db3-962e-b91ec4604e99	adba605c-4370-4db3-962e-b91ec4604e99	f	\N	2018-07-18 09:35:56.699	2019-05-17 16:44:33.329
53fd322d-7f6d-4796-ba88-3880a256f13c	2b58d456-e891-4433-b9c2-f0086669ae0a	2b58d456-e891-4433-b9c2-f0086669ae0a	f	\N	2018-09-24 20:40:03.483	2019-05-17 16:44:33.331
591cc010-2cf8-4da3-b75d-53dee0107062	6c764cc6-4e3d-4eac-96cf-a3f403c93e8c	6c764cc6-4e3d-4eac-96cf-a3f403c93e8c	f	\N	2019-04-11 12:24:40.149	2019-05-17 16:44:33.339
593ef32c-2f01-4277-a6a9-2250fd5bb5fe	1b8e9931-cbea-4ee7-b2b0-2c5911b4e575	1b8e9931-cbea-4ee7-b2b0-2c5911b4e575	f	\N	2019-07-26 11:45:14.13	2019-11-05 13:45:03.634
5a322949-aca5-4518-9920-fbd4de84a82d	f4240c47-913e-4c1a-8e54-e80eb1e7961d	f4240c47-913e-4c1a-8e54-e80eb1e7961d	f	\N	2019-05-17 08:42:27.725	2019-05-17 16:44:33.34
5bf7da04-f79c-4a31-8eee-fddc2b157421	fc19f48f-0098-47a0-b0ad-040cf25c7270	2d586171-ca0e-439d-8cec-0203cbecac07	f	\N	2019-04-18 10:17:26.956	2019-07-09 12:53:55.593
5d585f86-15ec-42a4-9a1a-87e57959cfbf	2e68de1c-51d9-4cb1-86e1-bdfb87a28239	2e68de1c-51d9-4cb1-86e1-bdfb87a28239	f	\N	2018-09-18 12:22:29.434	2019-05-17 16:44:33.345
5ff402db-77c2-499c-a7db-a62d31d86cc4	9962d47f-0f4a-436b-92d8-6045efd60396	0546d6b9-63bd-466e-bc05-c467fd7e2d61	f	\N	2019-04-16 18:47:59.441	2019-06-03 13:22:18.717
64269d16-2710-4919-88ec-3b09c89ea004	f9455e7a-bd1a-4cb7-9556-b7ede4f93fc3	f9455e7a-bd1a-4cb7-9556-b7ede4f93fc3	f	\N	2018-10-30 13:34:43.925	2019-10-18 09:55:45.862
6828d30e-b9ec-48c7-b96c-81ef01a0a3b1	ed0c3959-bfb2-4a8e-927a-17c4d03c9261	ed0c3959-bfb2-4a8e-927a-17c4d03c9261	f	\N	2018-11-02 11:57:16.704	2019-05-17 16:44:33.351
683ea6c2-5d33-4363-8061-c811b1381f25	a7d001e5-d6e8-4f82-9d08-ea7487e2689f	a7d001e5-d6e8-4f82-9d08-ea7487e2689f	f	\N	2019-10-04 16:49:49.679	2019-10-07 14:41:17.979
69370958-2898-4d1e-96ad-ab14278ad961	d1113914-c2e4-4067-8c3a-68981d786a75	\N	f	\N	2019-10-04 11:33:04.576	2019-10-04 11:33:04.576
6ffd89b1-3484-4a17-b5b4-e96ecdc6b4f9	c93c3500-2a0f-4cd6-b5c6-0490b1e014d1	c93c3500-2a0f-4cd6-b5c6-0490b1e014d1	f	\N	2019-07-01 18:32:06.308	2019-07-01 18:35:44.28
76534a2a-04cd-4fd7-b891-0a1e61b1a859	c3973631-3038-4bdb-b27e-25b8fd82cf24	0f73fef5-7269-41f3-9438-9830a457b6a0	f	\N	2019-05-22 12:27:00.449	2019-06-11 15:27:56.672
7ca937a7-a2b0-4da6-b8f7-a26dffda3827	3048660e-c036-47b8-9bde-6ef96ff609a7	3048660e-c036-47b8-9bde-6ef96ff609a7	f	\N	2019-04-17 07:24:24.397	2019-05-17 16:44:33.358
8257a204-4cc2-48d6-b73f-189c34aedc2c	f2b7c8d8-a7c1-4334-9c0d-01ea70822baf	f2b7c8d8-a7c1-4334-9c0d-01ea70822baf	f	\N	2018-09-21 12:02:21.196	2019-05-17 16:44:33.361
86a1e1fe-c026-49f7-91c9-3fb5a77e0172	4c7ce396-0685-4b66-bcfc-6561dd7dad33	4c7ce396-0685-4b66-bcfc-6561dd7dad33	f	\N	2018-03-05 09:50:08.33	2019-05-17 16:44:33.363
9469fbf0-9fc2-451d-94d9-5fbfde5b5974	a0867428-0bdb-4191-af2f-4c19637ef40b	a0867428-0bdb-4191-af2f-4c19637ef40b	f	\N	2019-09-09 08:55:26.839	2019-11-08 10:20:44.073
95e0af1d-bf6a-46ca-b0f7-665b23d00be3	ae0ea552-4a97-483b-b456-1c304491a5d5	ae0ea552-4a97-483b-b456-1c304491a5d5	f	\N	2019-10-21 15:52:05.046	2019-10-31 10:27:27.03
965059bc-25b4-44b0-add8-b6fc5144be9d	a2ed6aec-ecd7-4390-a4d4-d3047424fc84	1d83162a-edaf-412b-b004-295992eb5caa	f	\N	2019-04-11 12:14:30.963	2019-09-19 13:01:06.997
968b8147-92ba-458d-9fe1-941d9f7c0415	398300f4-1394-4514-9ad4-8809680b92a4	398300f4-1394-4514-9ad4-8809680b92a4	f	\N	2018-10-05 09:10:45.768	2019-05-17 16:44:33.371
96e19b30-4f82-4a40-82ed-e8640962be93	a090b2b0-0753-4771-934e-660b0368113c	f5879d20-abff-479d-aaa4-b417a3725998	f	\N	2018-07-24 15:09:05.362	2019-05-17 16:44:33.424
9ac7acb5-cef0-48fd-8cf4-963059442f2c	f0216d57-8d4c-4863-a3e8-9ef3ff168f1f	\N	f	\N	2018-09-24 09:04:31.989	2019-05-17 16:44:33.426
9b9e7218-e086-4c61-991f-6ec22e7d7a82	8a780107-a9fe-4871-ab31-32c7d920518b	be5383eb-fa12-4884-bdc8-7c2cb516c5b5	f	\N	2019-07-26 15:06:54.583	2020-02-11 14:37:51.164
9ce3e0fd-7578-421b-8241-59f6ed3adbd8	45c44f30-c90a-4deb-9fa7-ef270aa09c69	45c44f30-c90a-4deb-9fa7-ef270aa09c69	f	\N	2018-11-05 09:40:49.287	2019-05-17 16:44:33.377
a55a982f-2b8f-4672-8a5a-f4560a42ec1d	84d3cfd1-b476-4bd9-a775-7c0c421c3937	\N	f	\N	2018-06-13 15:52:13.658	2019-05-17 16:44:33.428
a9d7d59a-8ff8-4ee3-84c0-e49f6312b185	fa0a5930-c733-4a8f-91bf-d4bad9d1ea9e	fa0a5930-c733-4a8f-91bf-d4bad9d1ea9e	f	\N	2019-09-20 11:35:27.885	2019-10-03 14:14:32.757
aed0ee71-a4b8-4afe-8a14-339f79ec5a6f	5b12f27b-6a9b-4179-9fb8-7f6032303877	5b12f27b-6a9b-4179-9fb8-7f6032303877	f	\N	2018-09-24 22:58:28.635	2019-05-17 16:44:33.379
b0457d83-b3aa-46d2-a6f8-cbc553780f33	97aad934-5d1e-4132-a61c-46f33d1b318d	97aad934-5d1e-4132-a61c-46f33d1b318d	f	\N	2018-10-31 16:55:52.492	2019-05-17 16:44:33.382
ba1002d7-d4db-4019-b242-8118054051a4	543b5efa-eb96-4868-8bad-1d96e99ab93f	\N	f	\N	2019-07-29 09:30:03.74	2019-07-29 09:30:03.74
bca97d30-14f3-418d-8827-a2799c5e9a0c	b2440bc7-f3d0-4bd8-8fa5-28952fd37f62	b2440bc7-f3d0-4bd8-8fa5-28952fd37f62	f	\N	2019-08-09 17:08:29.812	2019-09-18 14:57:21.852
c2470fd2-9687-4041-ac58-784894171840	2162bbbb-ec25-47ff-8e05-f70f6125981d	2162bbbb-ec25-47ff-8e05-f70f6125981d	f	\N	2019-09-12 10:33:17.091	2019-10-24 10:51:11.151
c41cf5a6-3312-4e3b-b419-0f7d972f3305	e1785c86-0096-4e1e-a799-a2cb273c9a29	e1785c86-0096-4e1e-a799-a2cb273c9a29	f	\N	2018-10-31 09:53:47.426	2019-05-17 16:44:33.385
c4500d42-30da-413d-aca9-7b56f844a055	969ca173-fbdd-4e26-8f2e-1d9ba8521bdc	969ca173-fbdd-4e26-8f2e-1d9ba8521bdc	f	\N	2019-04-16 12:51:47.206	2019-05-17 16:44:33.387
cff6f9a9-d0f3-45c2-9370-dc0457c6bbf0	50938cdd-6855-4761-9d67-86557093a682	92fb0fee-5aa7-409c-87ef-63cb3f3c70f4	f	\N	2019-04-11 12:16:24.724	2019-06-03 14:50:32.923
d03bcbfe-b67b-482c-ba1d-24fb5f6c5dc2	76fdb150-ceae-4033-8f39-bb97a5332fc5	76fdb150-ceae-4033-8f39-bb97a5332fc5	f	\N	2019-04-17 07:18:47.519	2019-05-17 16:44:33.393
d0d0aa0f-8aba-416c-8951-f3e8fe9f20cc	45d04c50-df12-4f29-93dd-4b6721870f4e	45d04c50-df12-4f29-93dd-4b6721870f4e	f	\N	2018-12-17 15:02:00.317	2019-05-17 16:44:33.396
d1ec7b30-8e9e-4b3e-b075-9cd9557fee8b	ab656a52-cd55-450b-818f-a33ac3996297	ab656a52-cd55-450b-818f-a33ac3996297	f	\N	2018-06-13 11:47:01.189	2019-05-17 16:44:33.398
dc557d44-d90e-4a3c-ba8f-4cc9ee164fda	0702913b-f954-469f-a05f-5d3fc616daf2	0702913b-f954-469f-a05f-5d3fc616daf2	f	\N	2019-04-15 12:14:37.448	2019-05-17 16:44:33.4
dee9deb8-6ed9-45d8-80d4-efc4614d2113	86b9c834-bb74-4e19-8743-cf23e166f711	86b9c834-bb74-4e19-8743-cf23e166f711	f	\N	2019-04-16 18:10:19.424	2019-05-17 16:44:33.402
e357b275-3cc8-455b-b7d7-0adaefb51040	8b823726-37c0-487e-a0d8-7e10ea57ea94	8b823726-37c0-487e-a0d8-7e10ea57ea94	f	\N	2018-11-28 12:49:52.964	2019-11-22 17:38:33.08
ea37dc2f-328b-452f-b05b-265a8a48382d	264b9596-95dc-41e2-a3ab-ce8a94542055	\N	f	\N	2018-09-24 11:39:20.761	2019-05-17 16:44:33.433
ea887e3a-1e9d-47cf-995a-ce060ae1fc4e	4def88a9-de8c-4f18-a9ca-f75e9cc516f5	4def88a9-de8c-4f18-a9ca-f75e9cc516f5	f	\N	2019-10-08 12:30:02.955	2019-11-06 13:26:43.158
ed39ed50-0118-4ac2-b047-a8c0960dbd48	59e3bb7c-abf0-41ea-9b22-000c862b8d13	59e3bb7c-abf0-41ea-9b22-000c862b8d13	f	\N	2019-07-30 19:34:58.085	2019-08-05 17:33:48.643
f58cf618-df78-481c-b2ce-450bac89273a	06bc889b-d859-4d90-87a8-9eaa41cc6295	\N	f	\N	2019-04-16 12:52:48.772	2019-05-17 16:44:33.436
f58f3fd8-7808-4074-b520-8edb531521e2	757334b2-1690-4b68-8686-1ab99dbc7c17	757334b2-1690-4b68-8686-1ab99dbc7c17	f	\N	2018-11-02 13:41:46.319	2019-05-17 16:44:33.407
fdc739f6-fe53-4271-9c8c-a3e05d12fcac	8ab7a996-318d-48c1-baf4-62d6f0ce134a	8ab7a996-318d-48c1-baf4-62d6f0ce134a	f	\N	2019-07-01 16:43:27.512	2019-11-05 13:44:29.482
\.


--
-- Data for Name: trackback; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.trackback (id, asset_identifier, title, excerpt, url, blog_name, track_date) FROM stdin;
\.


--
-- Name: trackback_sequence; Type: SEQUENCE SET; Schema: public; Owner: dotcms_dev
--

SELECT pg_catalog.setval('public.trackback_sequence', 1, false);


--
-- Data for Name: tree; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.tree (child, parent, relation_type, tree_order) FROM stdin;
\.


--
-- Data for Name: user_; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.user_ (userid, companyid, createdate, mod_date, password_, passwordencrypted, passwordexpirationdate, passwordreset, firstname, middlename, lastname, nickname, male, birthday, emailaddress, smsid, aimid, icqid, msnid, ymid, favoriteactivity, favoritebibleverse, favoritefood, favoritemovie, favoritemusic, languageid, timezoneid, skinid, dottedskins, roundedskins, greeting, resolution, refreshrate, layoutids, comments, logindate, loginip, lastlogindate, lastloginip, failedloginattempts, agreedtotermsofuse, active_, delete_in_progress, delete_date) FROM stdin;
dotcms.org.default	default	2020-03-26 00:34:56.578	2020-03-26 00:34:56.585	password	t	\N	f				\N	t	2020-03-26 00:34:56.578	default@dotcms.com	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	en_US	America/New_York	\N	f	f	Welcome!	\N	\N	\N	\N	2020-03-26 00:34:56.578	\N	\N	\N	0	f	t	f	\N
system	dotcms.org	2020-03-26 00:34:56.822	2020-03-26 00:34:56.823	1:1:CKlFHs+CgjgHPI+mdbpcYcwQuOHdkCoG:i=4e20:/OTaJ3tb2aluiYNG/YZp+uOdtWg4noJE	t	\N	f	system user	\N	system user	\N	t	\N	system@dotcmsfakeemail.org	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	en_US	America/New_York	\N	f	f	welcome, system system!	\N	\N	\N	\N	\N	\N	\N	\N	0	f	t	f	\N
dotcms.org.2808	dotcms.org	2013-03-26 07:38:54.094	2020-03-26 00:34:56.893	1:1:D03Ig8n1wpQZsc068xhLDKcxKi/Qb7CU:i=4e20:WU7SofAmNWm0TBWbsaWabMN11XN7M483	t	\N	f	Admin2	\N	User	\N	t	\N	admin2@dotcms.com	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	en_US	America/New_York		f	f	Welcome, dotcms.org.2807 dotcms.org.2807!	\N	\N	\N	\N	\N	\N	2020-02-18 17:37:30.177	179.50.134.31	0	f	t	f	\N
dotcms.org.1	dotcms.org	2008-03-06 12:36:01	2020-03-26 01:08:25.184	1:1:EBk/HSdzfiWh52GO9xxbBJhZgsb2jd9Q:i=4e20:LnjrBImIZ2XRA6woT8lSZmGNrDP8LKgE	t	\N	f	Admin		User		t	\N	admin@dotcms.com	\N	\N	\N	\N	\N	48190c8c-42c4-46af-8d1a-0cd5db894797	\N	\N	\N	\N	en_US	US/Eastern		f	f	Welcome, Test Test!	1024x768	900	\N	\N	2010-03-17 21:10:52.186	0:0:0:0:0:0:0:1	2020-03-26 01:08:25.033	127.0.0.1	0	f	t	f	\N
036fd43a-6d98-46e0-b22e-bae02cb86f0c	dotcms.org	2018-12-17 14:46:37.639	2020-03-26 01:09:59.493	1:1:WmfMhoni7OzsPP43PFrrndrhAV/bCEMW:i=4e20:HsqV8gjGTdIv01ww596EH+SGN6s9pUIn	t	\N	f	Jason	\N	Smith	\N	t	\N	jason@dotcms.com	\N	\N	C8d0laNQdBKJIpClpFDhzGCtt9tXXg1570033581916:1570033581916	\N	\N	\N	\N	\N	\N	\N	en_US	GMT	\N	f	f	Welcome, 036fd43a-6d98-46e0-b22e-bae02cb86f0c 036fd43a-6d98-46e0-b22e-bae02cb86f0c!	\N	\N	\N	\N	\N	\N	2019-12-17 18:57:20.991	99.74.139.20	4	f	f	f	\N
anonymous	dotcms.org	2018-12-07 12:40:58.222	2020-03-26 00:34:57.671	1:1:JOly7WgzskJsS9IlzjxxtQxe3KzKvr2Q:i=4e20:Aug74RETxLcQSultEYeMB+mIRhgYiLuh	t	\N	f	anonymous user	\N	anonymous	\N	t	\N	anonymous@dotcmsfakeemail.org	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	en_US	GMT	\N	f	f	welcome, anonymous anonymous!	\N	\N	\N	\N	\N	\N	\N	\N	0	f	t	f	\N
\.


--
-- Data for Name: user_comments; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.user_comments (inode, user_id, cdate, comment_user_id, type, method, subject, ucomment, communication_id) FROM stdin;
\.


--
-- Data for Name: user_filter; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.user_filter (inode, title, firstname, middlename, lastname, emailaddress, birthdaytypesearch, birthday, birthdayfrom, birthdayto, lastlogintypesearch, lastloginsince, loginfrom, loginto, createdtypesearch, createdsince, createdfrom, createdto, lastvisittypesearch, lastvisitsince, lastvisitfrom, lastvisitto, city, state, country, zip, cell, phone, fax, active_, tagname, var1, var2, var3, var4, var5, var6, var7, var8, var9, var10, var11, var12, var13, var14, var15, var16, var17, var18, var19, var20, var21, var22, var23, var24, var25, categories) FROM stdin;
\.


--
-- Data for Name: user_preferences; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.user_preferences (id, user_id, preference, pref_value) FROM stdin;
1	dotcms.org.4	window_code_width	950px
2	dotcms.org.4	window_code_height	450px
3	dotcms.org.1	window_code_width	450px
4	dotcms.org.1	window_code_height	350px
\.


--
-- Name: user_preferences_seq; Type: SEQUENCE SET; Schema: public; Owner: dotcms_dev
--

SELECT pg_catalog.setval('public.user_preferences_seq', 5, false);


--
-- Data for Name: user_proxy; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.user_proxy (inode, user_id, prefix, suffix, title, school, how_heard, company, long_lived_cookie, website, graduation_year, organization, mail_subscription, var1, var2, var3, var4, var5, var6, var7, var8, var9, var10, var11, var12, var13, var14, var15, var16, var17, var18, var19, var20, var21, var22, var23, var24, var25, last_result, last_message, no_click_tracking, cquestionid, cqanswer, chapter_officer) FROM stdin;
3909f53d-fd22-45e7-a6dc-7eb8d99fa0b1	user-ddb808e6-4f68-4f7a-96d0-81277a66953f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	\N	f	\N	\N	\N
5c7d0674-07d6-4f62-b1bc-0e10fe6cb3ba	user-b1b27655-44bb-4f81-8688-a8763005a377	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	\N	f	\N	\N	\N
9eda551c-f698-4976-9f86-db88fecabc1d	9522e2cb-8ff2-45b2-b4f6-f1cc7252d83c	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	\N	f	\N	\N	\N
f762f699-83e3-466a-95ad-533b37033081	036fd43a-6d98-46e0-b22e-bae02cb86f0c	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	\N	f	\N	\N	\N
cdb421a2-0a0d-4aad-9b5c-d6cfa6359379	86fe5be1-4624-4595-bf2d-af8d559414b1	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	\N	f	\N	\N	\N
9546b9e0-ba09-4a21-aec7-55a80fb5bdfc	dotcms.org.2909	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	\N	f	\N	\N	\N
5dc84276-7226-4440-8dfb-16ba56b1afd0	dotcms.org.2908	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	\N	f	\N	\N	\N
38ff74b9-a772-418e-8c4c-26807d8f8127	dotcms.org.2811	mr			\N	\N	\N	\N	\N	0	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	\N	f	\N	\N	\N
097f609b-7da5-402e-8a58-e2a92678223d	1b865d6a-c292-48c3-8705-0cdfc955dd5e	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	\N	f	\N	\N	\N
07000663-738b-4cfd-990c-364b49f741f9	5fbee5ef-a824-41df-85a6-39b3157db321	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	\N	f	\N	\N	\N
b7dab462-1533-4f10-91c4-5e824f3fbca2	2ad502fa-6a73-42c1-a3f7-daebb76731d7	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	\N	f	\N	\N	\N
1b837701-531c-4a5f-b9f1-7b7a62fbd270	e6bc8fb9-10fa-40aa-b658-2e817faa3764	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	\N	f	\N	\N	\N
cfa80329-12e4-484d-8aaf-568a981d9102	cfbc9918-3e0e-4596-b89f-573b0dcae965	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	\N	f	\N	\N	\N
80c762bc-d5b7-4a4a-8132-b07b72a5232e	09dddbf5-1303-4b5f-9bf2-c18d6e6becf6	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	\N	f	\N	\N	\N
b01e9978-b28a-4f37-93d9-aebcadf6a230	dotcms.org.2808	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	\N	f	\N	\N	\N
cafb8edc-a3a8-40e6-8ea8-452ba61d5420	dotcms.org.2806	mr	III	Chief Visionary Officer	\N	\N	Great Food & Stuff LLC	\N	\N	0	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	\N	f	\N	\N	\N
fad56446-b9c1-40ce-aee0-fc63b0c945b8	dotcms.org.2804	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	\N	f	\N	\N	\N
c84946af-d727-4500-9f61-7522adec00d6	dotcms.org.2802	mr	\N	\N	\N	\N	\N	\N	\N	0	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	\N	f	\N	\N	\N
42ae54e6-0ee5-4d10-8a22-cfc009575db6	dotcms.org.2800	mr	\N	\N	\N	\N	\N	\N	\N	0	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	\N	f	\N	\N	\N
d7e0acef-1773-4c5b-ad0c-f915c26336e7	dotcms.org.2798	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	\N	f	\N	\N	\N
3d900064-6801-4e46-bc88-f7fd5c9b1720	dotcms.org.2795	\N	\N	\N	\N	\N	\N	\N	\N	0	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	\N	f	\N	\N	\N
a7472d3b-7f3e-40c0-98a4-1c3a4c29d697	dotcms.org.2793	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	\N	f	\N	\N	\N
943833e9-88db-4a77-9b15-a8a687558074	dotcms.org.2791	\N	\N	\N	\N	\N	\N	\N	\N	0	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	\N	f	\N	\N	\N
6d683b06-3a0a-45dd-b4df-6951da8680a7	dotcms.org.2789	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	\N	f	\N	\N	\N
95450e1f-f553-4eeb-ac86-0fead1c047d0	dotcms.org.2787	\N	\N	\N	\N	\N	\N	\N	\N	0	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	\N	f	\N	\N	\N
9f073702-33c8-4b9d-adba-36946ba1ee9c	dotcms.org.default	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	\N	f	\N	\N	\N
82be01b1-956e-4808-abf5-68b67c95026f	dotcms.org.2785	dr	s	t	\N	\N	\N	\N	\N	0	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	\N	f	\N	\N	\N
f314b9ad-6e3d-4265-8db3-fdf78a2cb022	dotcms.org.2783	\N	\N	\N	\N	\N	\N	\N	\N	0	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	\N	f	\N	\N	\N
86805713-2607-4f32-a3fb-f7f949f1b6ba	dotcms.org.2781	mr	Jr.	Engineer	\N	\N	\N	\N	\N	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	\N	f	\N	\N	\N
7f3e33dd-b0e0-4651-a542-90e476a249d8	dotcms.org.2779	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	\N	f	\N	\N	\N
f54bdf6d-4073-4fe2-8d23-d3cfd6594529	dotcms.org.2777	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	\N	f	\N	\N	\N
37432fed-0c09-4e44-8343-cdfb898e7c04	dotcms.org.2775	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	\N	f	\N	\N	\N
b0288656-2940-4088-9820-63c341ecae62	dotcms.org.2773	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	\N	f	\N	\N	\N
13c2374e-f959-47fa-833a-6ae81b8395bb	anonymous	\N	\N	\N	\N	\N	\N	\N	\N	0	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	\N	f	\N	\N	\N
530af300-0f33-47a6-884b-5f9140c2b8d9	dotcms.org.2771	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	\N	f	\N	\N	\N
2c3ef021-f9ee-459d-ac57-63e58f592ce3	dotcms.org.2769	\N	\N	\N	\N	\N	\N	\N	\N	0	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	\N	f	\N	\N	\N
92b0192f-7e89-4d3b-83a6-df60ca3a11aa	dotcms.org.2767	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	\N	f	\N	\N	\N
75abaca9-3878-4e4f-b298-eef7de079399	dotcms.org.2765	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	\N	f	\N	\N	\N
f74f3681-5ec2-4a2d-8d18-f6f67bee34ce	dotcms.org.2482	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	\N	f	\N	\N	\N
1a01290d-9c5f-4351-b812-d31b7504da23	system	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	\N	f	\N	\N	\N
7aa8b3b5-523d-42ab-b072-7a8c4ad494fa	dotcms.org.1	\N	\N	\N	\N	\N	\N	\N	\N	0	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	\N	f	\N	\N	\N
\.


--
-- Name: user_to_delete_seq; Type: SEQUENCE SET; Schema: public; Owner: dotcms_dev
--

SELECT pg_catalog.setval('public.user_to_delete_seq', 2, false);


--
-- Data for Name: users_cms_roles; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.users_cms_roles (id, user_id, role_id) FROM stdin;
d61479da-8529-41a0-873e-406acb320bb6	dotcms.org.1	e7d4e34e-5127-45fc-8123-d48b62d510e3
13dc6097-f52a-4ea9-9588-b892ef3797e6	dotcms.org.2808	73ec980e-d74f-4cec-a4d0-e319061e20b9
06541ecc-cd16-4331-82fb-fcfaf174fcc8	036fd43a-6d98-46e0-b22e-bae02cb86f0c	d3684242-00f2-48ab-b9ec-14ed91dc1321
0533a489-4a7c-4ffc-b11e-948ecacde6bd	anonymous	edecd377-2321-4803-aa8b-89797dd0d61f
04e2428c-5e30-4d16-9d32-43d0aac7845a	dotcms.org.1	02088e05-5ff5-43c2-a4fa-11a7272cb199
0fe923fe-187a-4fcf-a85f-4036cf0d9e8e	dotcms.org.2808	6f9d5449-8f48-4179-a2ad-1983d6217fef
14722a32-e98c-4417-ac4d-e119a4762e11	dotcms.org.2808	e828467a-f128-4d3c-8873-d967631bf130
2585ade7-288e-4a87-ab04-c637e523b0d6	dotcms.org.default	15aad986-6d7d-49e3-b643-344158a6e2a1
3d96ec34-ee03-46ff-a9ef-f6e33ae1a339	system	892ab105-f212-407f-8fb4-58ec59310a5e
442addbb-fbc9-4285-af32-ea7729556787	dotcms.org.1	e828467a-f128-4d3c-8873-d967631bf130
46bb8abd-1fbc-4369-a728-13d6d1a2880c	dotcms.org.1	f10eab25-ab4b-444f-b1b5-15a1a5948024
4f7488b5-7601-4c7b-a5ac-8cc6d7011162	dotcms.org.1	dbd027dc-9587-422f-a8be-c7c1ddd08691
58e2a9d0-cc59-48ee-b0a7-85cbd1f7c462	system	02088e05-5ff5-43c2-a4fa-11a7272cb199
59ca9239-09ea-4d9b-8c1f-bd7804a774b4	dotcms.org.1	a2d88e69-d575-45ec-9b52-0dc3a51468ed
6ef84cae-3f74-475e-902d-baaf39d7be2a	dotcms.org.2808	dbd027dc-9587-422f-a8be-c7c1ddd08691
84ad1cd4-ea14-4f95-9f56-7c8d1721567a	dotcms.org.2808	892ab105-f212-407f-8fb4-58ec59310a5e
87b92b3f-755a-4f1d-9b25-dab3e380f972	dotcms.org.2808	f10eab25-ab4b-444f-b1b5-15a1a5948024
8fde8676-b62e-459b-b26a-99c237ac6ea9	dotcms.org.1	892ab105-f212-407f-8fb4-58ec59310a5e
9d7b8298-11d6-4b31-b208-e3b9f498770e	dotcms.org.1	6f9d5449-8f48-4179-a2ad-1983d6217fef
9e6ad8a8-5d22-4432-859c-49f232e1fdac	dotcms.org.1	ff4d1504-a077-4874-b89b-9844d10d5b6d
b28e1c06-97d2-4dea-b195-8020d8d4f8c6	dotcms.org.2808	a2d88e69-d575-45ec-9b52-0dc3a51468ed
b6c7d818-013d-42ff-b79b-c644b882c071	anonymous	654b0931-1027-41f7-ad4d-173115ed8ec1
f1f7dc9c-818c-4310-ab27-b2f7ed75b241	dotcms.org.2808	02088e05-5ff5-43c2-a4fa-11a7272cb199
fa92481b-f362-4053-a28d-16e5587240e6	dotcms.org.2808	ff4d1504-a077-4874-b89b-9844d10d5b6d
f22d9e72-ec42-47cb-9ce6-aa6e677f5922	anonymous	999cd6bf-5cef-4729-8543-696086143884
\.


--
-- Data for Name: users_to_delete; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.users_to_delete (id, user_id) FROM stdin;
\.


--
-- Data for Name: usertracker; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.usertracker (usertrackerid, companyid, userid, modifieddate, remoteaddr, remotehost, useragent) FROM stdin;
\.


--
-- Data for Name: usertrackerpath; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.usertrackerpath (usertrackerpathid, usertrackerid, path, pathdate) FROM stdin;
\.


--
-- Data for Name: web_form; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.web_form (web_form_id, form_type, submit_date, prefix, first_name, middle_initial, middle_name, full_name, organization, title, last_name, address, address1, address2, city, state, zip, country, phone, email, custom_fields, user_inode, categories) FROM stdin;
\.


--
-- Data for Name: workflow_action; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.workflow_action (id, step_id, name, condition_to_progress, next_step_id, next_assign, my_order, assignable, commentable, requires_checkout, icon, show_on, use_role_hierarchy_assign, scheme_id) FROM stdin;
45f2136e-a567-49e0-8e22-155019ccfc1c	\N	Approve		f43c5d5a-fc51-4c67-a750-cc8f8e4a87f7	654b0931-1027-41f7-ad4d-173115ed8ec1	0	f	t	f	workflowIcon	EDITING,UNPUBLISHED,PUBLISHED,LISTING,LOCKED,UNLOCKED,NEW	f	2a4e1d2e-5342-4b46-be3d-80d3a2d9c0dd
1b84f952-e6c7-40a9-9b8a-06d764d4c8fd	\N	Archive		37cebe78-cf46-4153-be4c-9c2efd8ec04a	654b0931-1027-41f7-ad4d-173115ed8ec1	0	f	f	f	workflowIcon	EDITING,UNPUBLISHED,PUBLISHED,LISTING,LOCKED,UNLOCKED	f	2a4e1d2e-5342-4b46-be3d-80d3a2d9c0dd
f1e3e786-9095-4157-b756-ffc767e2cc12	\N	Copy Blog		currentstep	654b0931-1027-41f7-ad4d-173115ed8ec1	0	f	f	f	workflowIcon	PUBLISHED,LISTING,UNLOCKED	f	2a4e1d2e-5342-4b46-be3d-80d3a2d9c0dd
bf83c370-14cc-45f2-8cf7-e963da74eb29	\N	Destroy		currentstep	654b0931-1027-41f7-ad4d-173115ed8ec1	0	f	f	f	workflowIcon	EDITING,UNPUBLISHED,PUBLISHED,LISTING,LOCKED,UNLOCKED,NEW,ARCHIVED	f	2a4e1d2e-5342-4b46-be3d-80d3a2d9c0dd
2d1dc771-8fda-4b43-9e81-71d43a8c73e4	\N	Reset Workflow		5865d447-5df7-4fa8-81c8-f8f183f3d1a2	654b0931-1027-41f7-ad4d-173115ed8ec1	0	f	f	f	workflowIcon	EDITING,UNPUBLISHED,PUBLISHED,LISTING,LOCKED,UNLOCKED,NEW,ARCHIVED	f	2a4e1d2e-5342-4b46-be3d-80d3a2d9c0dd
8beed083-8999-4bb4-914b-ea0457cf9fd4	\N	Save		f43c5d5a-fc51-4c67-a750-cc8f8e4a87f7	e7d4e34e-5127-45fc-8123-d48b62d510e3	0	f	f	f	workflowIcon	EDITING,UNPUBLISHED,PUBLISHED,LOCKED,NEW	f	2a4e1d2e-5342-4b46-be3d-80d3a2d9c0dd
89685558-1449-4928-9cff-adda8648d54d	\N	Save and Publish		f43c5d5a-fc51-4c67-a750-cc8f8e4a87f7	654b0931-1027-41f7-ad4d-173115ed8ec1	0	f	f	f	workflowIcon	EDITING,UNPUBLISHED,PUBLISHED,LISTING,LOCKED,NEW	f	2a4e1d2e-5342-4b46-be3d-80d3a2d9c0dd
175009d6-9e4b-4ed2-ae31-7d019d3dc278	\N	Save and Publish		f43c5d5a-fc51-4c67-a750-cc8f8e4a87f7	e7d4e34e-5127-45fc-8123-d48b62d510e3	0	f	f	f	workflowIcon	EDITING,UNPUBLISHED,PUBLISHED,LISTING,LOCKED,UNLOCKED,NEW,ARCHIVED	f	2a4e1d2e-5342-4b46-be3d-80d3a2d9c0dd
d4b61549-84e3-4e8e-8182-8e34f12f9063	\N	Save as Draft		5865d447-5df7-4fa8-81c8-f8f183f3d1a2	654b0931-1027-41f7-ad4d-173115ed8ec1	0	f	f	f	workflowIcon	EDITING,UNPUBLISHED,PUBLISHED,LOCKED,NEW,ARCHIVED	f	2a4e1d2e-5342-4b46-be3d-80d3a2d9c0dd
ae569f3a-c96f-4c44-926c-4741b2ad344f	\N	Send Email		currentstep	654b0931-1027-41f7-ad4d-173115ed8ec1	0	f	f	f	workflowIcon		f	2a4e1d2e-5342-4b46-be3d-80d3a2d9c0dd
88794a29-d861-4aa5-b137-9a6af72c6fc0	\N	Send for Review		d95caaa6-1ece-42b2-8663-fb01e804a149	e7d4e34e-5127-45fc-8123-d48b62d510e3	0	f	f	f	workflowIcon	EDITING,UNPUBLISHED,LISTING,UNLOCKED	f	2a4e1d2e-5342-4b46-be3d-80d3a2d9c0dd
8d567403-a201-42de-9a48-10cea8a7bdb2	\N	Translate		f43c5d5a-fc51-4c67-a750-cc8f8e4a87f7	654b0931-1027-41f7-ad4d-173115ed8ec1	0	f	f	f	workflowIcon	EDITING,UNPUBLISHED,PUBLISHED,LISTING,LOCKED	f	2a4e1d2e-5342-4b46-be3d-80d3a2d9c0dd
4da13a42-5d59-480c-ad8f-94a3adf809fe	\N	Archive		d6b095b6-b65f-4bdb-bbfd-701d663dfee2	654b0931-1027-41f7-ad4d-173115ed8ec1	0	f	f	f	workflowIcon	UNPUBLISHED,LISTING,UNLOCKED,ARCHIVED	f	d61a59e1-a49c-46f2-a929-db2b4bfa88b2
963f6a04-5320-42e7-ab74-6d876d199946	\N	Copy		currentstep	654b0931-1027-41f7-ad4d-173115ed8ec1	0	f	f	f	workflowIcon	PUBLISHED,LISTING,LOCKED,UNLOCKED	f	d61a59e1-a49c-46f2-a929-db2b4bfa88b2
777f1c6b-c877-4a37-ba4b-10627316c2cc	\N	Delete		d6b095b6-b65f-4bdb-bbfd-701d663dfee2	654b0931-1027-41f7-ad4d-173115ed8ec1	0	f	f	f	workflowIcon	EDITING,LISTING,LOCKED,UNLOCKED,ARCHIVED	f	d61a59e1-a49c-46f2-a929-db2b4bfa88b2
1e0f1c6b-b67f-4c99-983d-db2b4bfa88b2	\N	Destroy		d6b095b6-b65f-4bdb-bbfd-701d663dfee2	654b0931-1027-41f7-ad4d-173115ed8ec1	0	f	f	f	workflowIcon	EDITING,LISTING,LOCKED,UNLOCKED,ARCHIVED	f	d61a59e1-a49c-46f2-a929-db2b4bfa88b2
b9d89c80-3d88-4311-8365-187323c96436	\N	Publish		dc3c9cd0-8467-404b-bf95-cb7df3fbc293	654b0931-1027-41f7-ad4d-173115ed8ec1	0	f	f	f	workflowIcon	EDITING,UNPUBLISHED,PUBLISHED,LISTING,LOCKED,UNLOCKED,NEW	f	d61a59e1-a49c-46f2-a929-db2b4bfa88b2
ceca71a0-deee-4999-bd47-b01baa1bcfc8	\N	Save		ee24a4cb-2d15-4c98-b1bd-6327126451f3	654b0931-1027-41f7-ad4d-173115ed8ec1	0	f	f	f	workflowIcon	EDITING,UNPUBLISHED,PUBLISHED,LOCKED,NEW	f	d61a59e1-a49c-46f2-a929-db2b4bfa88b2
c92f9aa1-9503-4567-ac30-d3242b54d02d	\N	Unarchive		ee24a4cb-2d15-4c98-b1bd-6327126451f3	654b0931-1027-41f7-ad4d-173115ed8ec1	0	f	f	f	workflowIcon	LISTING,LOCKED,UNLOCKED,ARCHIVED	f	d61a59e1-a49c-46f2-a929-db2b4bfa88b2
38efc763-d78f-4e4b-b092-59cd8c579b93	\N	Unpublish		ee24a4cb-2d15-4c98-b1bd-6327126451f3	654b0931-1027-41f7-ad4d-173115ed8ec1	0	f	f	f	workflowIcon	PUBLISHED,LISTING,LOCKED,UNLOCKED	f	d61a59e1-a49c-46f2-a929-db2b4bfa88b2
\.


--
-- Data for Name: workflow_action_class; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.workflow_action_class (id, action_id, name, my_order, clazz) FROM stdin;
f1cead4a-c92e-4c20-ae30-93c3b754a833	45f2136e-a567-49e0-8e22-155019ccfc1c	Notify Assignee	0	com.dotmarketing.portlets.workflows.actionlet.NotifyAssigneeActionlet
abba75a1-2bdf-48d6-a138-6e0cefb0f129	45f2136e-a567-49e0-8e22-155019ccfc1c	Unlock content	1	com.dotmarketing.portlets.workflows.actionlet.CheckinContentActionlet
631cdc09-7336-4499-bd16-f8fe58d10026	45f2136e-a567-49e0-8e22-155019ccfc1c	Publish content	2	com.dotmarketing.portlets.workflows.actionlet.PublishContentActionlet
cb260982-2c3f-45e7-b7ea-ab03e1a355f3	1b84f952-e6c7-40a9-9b8a-06d764d4c8fd	Lock content	0	com.dotmarketing.portlets.workflows.actionlet.CheckoutContentActionlet
b4a28af6-487c-4e56-bca1-29f8c96ff5d7	1b84f952-e6c7-40a9-9b8a-06d764d4c8fd	Set Value	1	com.dotmarketing.portlets.workflows.actionlet.SetValueActionlet
b75e11c2-216d-4502-bcaa-cdcbe253cd61	1b84f952-e6c7-40a9-9b8a-06d764d4c8fd	Save content	2	com.dotmarketing.portlets.workflows.actionlet.SaveContentActionlet
f595591f-a2f1-4624-af40-bdb0fe788e7d	1b84f952-e6c7-40a9-9b8a-06d764d4c8fd	Unpublish content	3	com.dotmarketing.portlets.workflows.actionlet.UnpublishContentActionlet
45587874-fc45-4aad-9082-745a9645e244	1b84f952-e6c7-40a9-9b8a-06d764d4c8fd	Archive content	4	com.dotmarketing.portlets.workflows.actionlet.ArchiveContentActionlet
76aa50d0-7d41-49af-a80c-af1d7e24d04a	f1e3e786-9095-4157-b756-ffc767e2cc12	Copy Contentlet	0	com.dotmarketing.portlets.workflows.actionlet.CopyActionlet
eaab7268-fa86-4340-b360-a724f759136f	bf83c370-14cc-45f2-8cf7-e963da74eb29	Unpublish content	0	com.dotmarketing.portlets.workflows.actionlet.UnpublishContentActionlet
10b415ad-d95a-4ad5-847a-33571938b4ea	bf83c370-14cc-45f2-8cf7-e963da74eb29	Archive content	1	com.dotmarketing.portlets.workflows.actionlet.ArchiveContentActionlet
df8f68b6-d546-4c99-bc92-60fb19663965	bf83c370-14cc-45f2-8cf7-e963da74eb29	Delete content	2	com.dotmarketing.portlets.workflows.actionlet.DeleteContentActionlet
214253d0-2f94-41ad-b8c8-9406fe245a77	2d1dc771-8fda-4b43-9e81-71d43a8c73e4	Unarchive content	0	com.dotmarketing.portlets.workflows.actionlet.UnarchiveContentActionlet
99205d78-5e4b-4bd1-866d-aa3cf5b5b759	2d1dc771-8fda-4b43-9e81-71d43a8c73e4	Unlock content	1	com.dotmarketing.portlets.workflows.actionlet.CheckinContentActionlet
965af324-75e9-4ae3-9d56-e9b4128efa19	8beed083-8999-4bb4-914b-ea0457cf9fd4	Save content	0	com.dotmarketing.portlets.workflows.actionlet.SaveContentActionlet
f64a9d26-ee20-4c88-905b-dd708ea4025c	8beed083-8999-4bb4-914b-ea0457cf9fd4	Unlock content	1	com.dotmarketing.portlets.workflows.actionlet.CheckinContentActionlet
6f3a78c3-eb93-47c2-8018-5ba33c7b08a0	89685558-1449-4928-9cff-adda8648d54d	Save content	0	com.dotmarketing.portlets.workflows.actionlet.SaveContentActionlet
8e17634f-99d7-443c-bdba-a21d131f7a4d	89685558-1449-4928-9cff-adda8648d54d	Publish content	1	com.dotmarketing.portlets.workflows.actionlet.PublishContentActionlet
f83b949d-37d8-4178-bca9-add88309b11d	89685558-1449-4928-9cff-adda8648d54d	Unlock content	2	com.dotmarketing.portlets.workflows.actionlet.CheckinContentActionlet
4d519a71-0832-46d6-a2a6-017ca8643ada	175009d6-9e4b-4ed2-ae31-7d019d3dc278	Save content	0	com.dotmarketing.portlets.workflows.actionlet.SaveContentActionlet
d156ba99-ab12-4548-9beb-c3ccba013bc2	175009d6-9e4b-4ed2-ae31-7d019d3dc278	Publish content	1	com.dotmarketing.portlets.workflows.actionlet.PublishContentActionlet
ca6c04f1-86da-4efa-92ea-b35c97b3f7ab	175009d6-9e4b-4ed2-ae31-7d019d3dc278	Notify Assignee	2	com.dotmarketing.portlets.workflows.actionlet.NotifyAssigneeActionlet
02b17eca-bc64-4864-9981-7b3fe8ad8c01	175009d6-9e4b-4ed2-ae31-7d019d3dc278	Unlock content	3	com.dotmarketing.portlets.workflows.actionlet.CheckinContentActionlet
5309a94b-866c-467c-a131-fbaea3a84869	d4b61549-84e3-4e8e-8182-8e34f12f9063	Set Value	0	com.dotmarketing.portlets.workflows.actionlet.SetValueActionlet
3376733a-b192-4aa3-9bf8-7e485d1bc6c8	d4b61549-84e3-4e8e-8182-8e34f12f9063	Save content	1	com.dotmarketing.portlets.workflows.actionlet.SaveContentActionlet
e9734cf0-c177-440c-90af-4db34deba502	ae569f3a-c96f-4c44-926c-4741b2ad344f	Notify Assignee	0	com.dotmarketing.portlets.workflows.actionlet.NotifyAssigneeActionlet
4335e9f9-8d02-48b0-986b-ba44619e6db5	88794a29-d861-4aa5-b137-9a6af72c6fc0	Unlock content	0	com.dotmarketing.portlets.workflows.actionlet.CheckinContentActionlet
3e2a14f5-c26d-4e10-82c8-8565bd711c3c	88794a29-d861-4aa5-b137-9a6af72c6fc0	Notify Assignee	1	com.dotmarketing.portlets.workflows.actionlet.NotifyAssigneeActionlet
95c06ac3-9430-41c0-825a-9c7bc3179886	8d567403-a201-42de-9a48-10cea8a7bdb2	Translate Content	0	com.dotmarketing.portlets.workflows.actionlet.TranslationActionlet
74c560b7-f71d-44cd-bb33-8016abb3f0f2	4da13a42-5d59-480c-ad8f-94a3adf809fe	Archive content	0	com.dotmarketing.portlets.workflows.actionlet.ArchiveContentActionlet
6bc6def5-0565-483d-a5bf-e42d4e424bf0	4da13a42-5d59-480c-ad8f-94a3adf809fe	Unlock content	1	com.dotmarketing.portlets.workflows.actionlet.CheckinContentActionlet
a0346612-62fe-4a8f-bdbc-528d25c71a13	963f6a04-5320-42e7-ab74-6d876d199946	Copy Contentlet	0	com.dotmarketing.portlets.workflows.actionlet.CopyActionlet
93f32847-87b7-4770-bd00-987446fd69b8	777f1c6b-c877-4a37-ba4b-10627316c2cc	Delete content	0	com.dotmarketing.portlets.workflows.actionlet.DeleteContentActionlet
74f42846-86b6-4660-bd00-789446fd67c8	1e0f1c6b-b67f-4c99-983d-db2b4bfa88b2	Destroy content	0	com.dotmarketing.portlets.workflows.actionlet.DestroyContentActionlet
b84879e9-545f-4436-b4c5-e76c1743d168	b9d89c80-3d88-4311-8365-187323c96436	Save content	0	com.dotmarketing.portlets.workflows.actionlet.SaveContentActionlet
9aacba54-b6f4-424c-97f2-56019cbdbbc7	b9d89c80-3d88-4311-8365-187323c96436	Publish content	1	com.dotmarketing.portlets.workflows.actionlet.PublishContentActionlet
6abcf2ab-16ae-4d84-9977-b6124d4d1f73	b9d89c80-3d88-4311-8365-187323c96436	Unlock content	2	com.dotmarketing.portlets.workflows.actionlet.CheckinContentActionlet
52c05cfd-5544-4fe1-9fa4-4e9d95059909	ceca71a0-deee-4999-bd47-b01baa1bcfc8	Save Draft content	0	com.dotmarketing.portlets.workflows.actionlet.SaveContentAsDraftActionlet
7e25aaa2-8371-479a-a978-01374c70decd	ceca71a0-deee-4999-bd47-b01baa1bcfc8	Unlock content	1	com.dotmarketing.portlets.workflows.actionlet.CheckinContentActionlet
a766e1a8-dd14-4b6a-b39e-98db6a258623	c92f9aa1-9503-4567-ac30-d3242b54d02d	Unarchive content	0	com.dotmarketing.portlets.workflows.actionlet.UnarchiveContentActionlet
4132cee3-393d-42ee-84f7-1084a015c4b3	38efc763-d78f-4e4b-b092-59cd8c579b93	Unpublish content	0	com.dotmarketing.portlets.workflows.actionlet.UnpublishContentActionlet
\.


--
-- Data for Name: workflow_action_class_pars; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.workflow_action_class_pars (id, workflow_action_class_id, key, value) FROM stdin;
6c44b7c9-26bf-4c92-989b-e1f15ccea898	f1cead4a-c92e-4c20-ae30-93c3b754a833	emailSubject	\N
07bbcaae-051d-4e73-bcdd-b0f973f112af	f1cead4a-c92e-4c20-ae30-93c3b754a833	emailBody	\N
1afa09d2-a834-4567-9465-3ae63b599e85	f1cead4a-c92e-4c20-ae30-93c3b754a833	isHtml	true
86a1b3ad-91b9-4c46-9415-aa828a95fdfc	b4a28af6-487c-4e56-bca1-29f8c96ff5d7	field	postingDate
dd525a7b-254b-45b0-b7ec-da43a9575c66	b4a28af6-487c-4e56-bca1-29f8c96ff5d7	value	#set($value='')
83a1cfc7-4f14-43ca-b77e-f7d1cc3758ea	ca6c04f1-86da-4efa-92ea-b35c97b3f7ab	emailSubject	There is a new Blog: $content.title
fdc358be-acba-49f5-bafc-f3535443399f	ca6c04f1-86da-4efa-92ea-b35c97b3f7ab	emailBody	There is a new Blog: $content.title
5b2f01c0-3ddd-4d85-be48-df83d01e70c7	ca6c04f1-86da-4efa-92ea-b35c97b3f7ab	isHtml	true
c4f4d55d-4cb7-4427-be8b-e79ee5b3ca2e	5309a94b-866c-467c-a131-fbaea3a84869	field	postingDate
0961a74f-30de-4e6a-88e2-55ee342977b6	5309a94b-866c-467c-a131-fbaea3a84869	value	#set($value="")
c4d63be6-586a-4edf-a2ad-621287aa5560	e9734cf0-c177-440c-90af-4db34deba502	emailSubject	\N
33b20055-98d5-4b72-9c72-160bc4205ec9	e9734cf0-c177-440c-90af-4db34deba502	emailBody	\N
c63f1807-cecd-4850-9709-4721bba27887	e9734cf0-c177-440c-90af-4db34deba502	isHtml	true
409885f9-ffe6-44d3-a574-824bb907bfb8	3e2a14f5-c26d-4e10-82c8-8565bd711c3c	emailSubject	\N
d7d143f6-2f7a-4235-8742-538178b3b62f	3e2a14f5-c26d-4e10-82c8-8565bd711c3c	emailBody	\N
3affc9e8-1416-4f07-a6c6-fa4bc665cdb4	3e2a14f5-c26d-4e10-82c8-8565bd711c3c	isHtml	true
923f2ed0-42c0-4c4f-8350-7c986ddd33f9	95c06ac3-9430-41c0-825a-9c7bc3179886	translateTo	all
ccf7ceb5-aaf9-4322-94fb-93a8478edd04	95c06ac3-9430-41c0-825a-9c7bc3179886	fieldTypes	text,wysiwyg,textarea
86ea3f85-8dc6-4d91-9806-8d88477217f1	95c06ac3-9430-41c0-825a-9c7bc3179886	ignoreFields	\N
c02b80c2-8028-453e-8066-5d6394bdf9c2	95c06ac3-9430-41c0-825a-9c7bc3179886	apiKey	AIzaSyCzeaNIUO33tW7wjyY5dXhtbayIJpKoUi4
\.


--
-- Data for Name: workflow_action_mappings; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.workflow_action_mappings (id, action, workflow_action, scheme_or_content_type) FROM stdin;
3d6be719-6b61-4ef8-a594-a9764e461597	NEW	ceca71a0-deee-4999-bd47-b01baa1bcfc8	d61a59e1-a49c-46f2-a929-db2b4bfa88b2
63865890-c863-43a1-ab61-4b495dba5eb5	EDIT	ceca71a0-deee-4999-bd47-b01baa1bcfc8	d61a59e1-a49c-46f2-a929-db2b4bfa88b2
3ec446c8-a9b6-47fe-830f-1e623493090c	UNPUBLISH	38efc763-d78f-4e4b-b092-59cd8c579b93	d61a59e1-a49c-46f2-a929-db2b4bfa88b2
99019118-df2c-4297-a5aa-2fe3fe0f52ce	UNARCHIVE	c92f9aa1-9503-4567-ac30-d3242b54d02d	d61a59e1-a49c-46f2-a929-db2b4bfa88b2
2016a72e-85c7-4ee0-936f-36ce52df355e	PUBLISH	b9d89c80-3d88-4311-8365-187323c96436	d61a59e1-a49c-46f2-a929-db2b4bfa88b2
e7b8c8a3-e605-473c-8680-6d95cac15c9b	ARCHIVE	4da13a42-5d59-480c-ad8f-94a3adf809fe	d61a59e1-a49c-46f2-a929-db2b4bfa88b2
3d73437e-3f1c-8e5c-ac97-a25e9cddf320	DESTROY	1e0f1c6b-b67f-4c99-983d-db2b4bfa88b2	d61a59e1-a49c-46f2-a929-db2b4bfa88b2
d073436e-3c10-4e4c-8c97-225e9cddf320	DELETE	777f1c6b-c877-4a37-ba4b-10627316c2cc	d61a59e1-a49c-46f2-a929-db2b4bfa88b2
f6d0e67a-42f6-4317-a527-2bf3e71a66b5	NEW	b9d89c80-3d88-4311-8365-187323c96436	persona
\.


--
-- Data for Name: workflow_action_step; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.workflow_action_step (action_id, step_id, action_order) FROM stdin;
8d567403-a201-42de-9a48-10cea8a7bdb2	5865d447-5df7-4fa8-81c8-f8f183f3d1a2	0
ae569f3a-c96f-4c44-926c-4741b2ad344f	5865d447-5df7-4fa8-81c8-f8f183f3d1a2	1
d4b61549-84e3-4e8e-8182-8e34f12f9063	5865d447-5df7-4fa8-81c8-f8f183f3d1a2	2
88794a29-d861-4aa5-b137-9a6af72c6fc0	5865d447-5df7-4fa8-81c8-f8f183f3d1a2	3
8beed083-8999-4bb4-914b-ea0457cf9fd4	5865d447-5df7-4fa8-81c8-f8f183f3d1a2	4
175009d6-9e4b-4ed2-ae31-7d019d3dc278	5865d447-5df7-4fa8-81c8-f8f183f3d1a2	5
45f2136e-a567-49e0-8e22-155019ccfc1c	d95caaa6-1ece-42b2-8663-fb01e804a149	0
1b84f952-e6c7-40a9-9b8a-06d764d4c8fd	d95caaa6-1ece-42b2-8663-fb01e804a149	1
8beed083-8999-4bb4-914b-ea0457cf9fd4	d95caaa6-1ece-42b2-8663-fb01e804a149	2
8d567403-a201-42de-9a48-10cea8a7bdb2	d95caaa6-1ece-42b2-8663-fb01e804a149	3
8beed083-8999-4bb4-914b-ea0457cf9fd4	f43c5d5a-fc51-4c67-a750-cc8f8e4a87f7	0
f1e3e786-9095-4157-b756-ffc767e2cc12	f43c5d5a-fc51-4c67-a750-cc8f8e4a87f7	1
89685558-1449-4928-9cff-adda8648d54d	f43c5d5a-fc51-4c67-a750-cc8f8e4a87f7	2
8d567403-a201-42de-9a48-10cea8a7bdb2	f43c5d5a-fc51-4c67-a750-cc8f8e4a87f7	3
2d1dc771-8fda-4b43-9e81-71d43a8c73e4	f43c5d5a-fc51-4c67-a750-cc8f8e4a87f7	4
1b84f952-e6c7-40a9-9b8a-06d764d4c8fd	f43c5d5a-fc51-4c67-a750-cc8f8e4a87f7	5
2d1dc771-8fda-4b43-9e81-71d43a8c73e4	37cebe78-cf46-4153-be4c-9c2efd8ec04a	0
89685558-1449-4928-9cff-adda8648d54d	37cebe78-cf46-4153-be4c-9c2efd8ec04a	1
bf83c370-14cc-45f2-8cf7-e963da74eb29	37cebe78-cf46-4153-be4c-9c2efd8ec04a	2
ceca71a0-deee-4999-bd47-b01baa1bcfc8	6cb7e3bd-1710-4eed-8838-d3db60f78f19	0
b9d89c80-3d88-4311-8365-187323c96436	6cb7e3bd-1710-4eed-8838-d3db60f78f19	1
777f1c6b-c877-4a37-ba4b-10627316c2cc	6cb7e3bd-1710-4eed-8838-d3db60f78f19	2
ceca71a0-deee-4999-bd47-b01baa1bcfc8	ee24a4cb-2d15-4c98-b1bd-6327126451f3	0
38efc763-d78f-4e4b-b092-59cd8c579b93	ee24a4cb-2d15-4c98-b1bd-6327126451f3	1
963f6a04-5320-42e7-ab74-6d876d199946	ee24a4cb-2d15-4c98-b1bd-6327126451f3	2
b9d89c80-3d88-4311-8365-187323c96436	ee24a4cb-2d15-4c98-b1bd-6327126451f3	3
4da13a42-5d59-480c-ad8f-94a3adf809fe	ee24a4cb-2d15-4c98-b1bd-6327126451f3	4
963f6a04-5320-42e7-ab74-6d876d199946	dc3c9cd0-8467-404b-bf95-cb7df3fbc293	0
38efc763-d78f-4e4b-b092-59cd8c579b93	dc3c9cd0-8467-404b-bf95-cb7df3fbc293	1
ceca71a0-deee-4999-bd47-b01baa1bcfc8	dc3c9cd0-8467-404b-bf95-cb7df3fbc293	2
4da13a42-5d59-480c-ad8f-94a3adf809fe	dc3c9cd0-8467-404b-bf95-cb7df3fbc293	3
b9d89c80-3d88-4311-8365-187323c96436	dc3c9cd0-8467-404b-bf95-cb7df3fbc293	4
c92f9aa1-9503-4567-ac30-d3242b54d02d	d6b095b6-b65f-4bdb-bbfd-701d663dfee2	0
777f1c6b-c877-4a37-ba4b-10627316c2cc	d6b095b6-b65f-4bdb-bbfd-701d663dfee2	1
1e0f1c6b-b67f-4c99-983d-db2b4bfa88b2	d6b095b6-b65f-4bdb-bbfd-701d663dfee2	2
\.


--
-- Data for Name: workflow_comment; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.workflow_comment (id, creation_date, posted_by, wf_comment, workflowtask_id) FROM stdin;
\.


--
-- Data for Name: workflow_history; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.workflow_history (id, creation_date, made_by, change_desc, workflowtask_id, workflow_action_id, workflow_step_id) FROM stdin;
\.


--
-- Data for Name: workflow_scheme; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.workflow_scheme (id, name, description, archived, mandatory, default_scheme, entry_action_id, mod_date) FROM stdin;
d61a59e1-a49c-46f2-a929-db2b4bfa88b2	System Workflow		f	f	f	\N	2020-03-26 00:35:21.869
2a4e1d2e-5342-4b46-be3d-80d3a2d9c0dd	Blogs		f	f	f	\N	2020-03-26 00:35:21.945
\.


--
-- Data for Name: workflow_scheme_x_structure; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.workflow_scheme_x_structure (id, scheme_id, structure_id) FROM stdin;
ffc83470-9541-4454-ad0f-10bea90be61b	d61a59e1-a49c-46f2-a929-db2b4bfa88b2	c6e3a3c6-a0c6-494b-9ae8-bde7322bc68e
2e90b858-0ead-413b-99a5-aa594f9cf680	d61a59e1-a49c-46f2-a929-db2b4bfa88b2	897cf4a9-171a-4204-accb-c1b498c813fe
ce124c80-16d6-47c9-9e26-3326bbfa998b	d61a59e1-a49c-46f2-a929-db2b4bfa88b2	33888b6f-7a8e-4069-b1b6-5c1aa9d0a48d
0c0106df-6563-4e08-ae67-1e8cdecb5c05	d61a59e1-a49c-46f2-a929-db2b4bfa88b2	f4d7c1b8-2c88-4071-abf1-a5328977b07d
203086df-f400-42f4-b05d-1b62e52be883	d61a59e1-a49c-46f2-a929-db2b4bfa88b2	855a2d72-f2f3-4169-8b04-ac5157c4380c
f54498d0-4fe3-443b-a507-78d7ff794039	d61a59e1-a49c-46f2-a929-db2b4bfa88b2	4d21b6d8-1711-4ae6-9419-89e2b1ae5a06
85d5b026-00cc-4422-9465-4087faed2ff3	d61a59e1-a49c-46f2-a929-db2b4bfa88b2	8e850645-bb92-4fda-a765-e67063a59be0
04ed7311-1fad-4e83-835a-dcf625b33ec3	d61a59e1-a49c-46f2-a929-db2b4bfa88b2	c541abb1-69b3-4bc5-8430-5e09e5239cc8
a78ad949-b2e0-44c3-bb34-e29d7353b101	d61a59e1-a49c-46f2-a929-db2b4bfa88b2	c938b15f-bcb6-49ef-8651-14d455a97045
fadef487-4618-4583-b2dc-df6f17777c68	d61a59e1-a49c-46f2-a929-db2b4bfa88b2	f6259cc9-5d78-453e-8167-efd7b72b2e96
ad9b798e-59d7-4a22-a051-b0ea1dd86a70	d61a59e1-a49c-46f2-a929-db2b4bfa88b2	2a3e91e4-fbbf-4876-8c5b-2233c1739b05
\.


--
-- Data for Name: workflow_step; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.workflow_step (id, name, scheme_id, my_order, resolved, escalation_enable, escalation_action, escalation_time) FROM stdin;
5865d447-5df7-4fa8-81c8-f8f183f3d1a2	Editing	2a4e1d2e-5342-4b46-be3d-80d3a2d9c0dd	0	f	f	\N	0
d95caaa6-1ece-42b2-8663-fb01e804a149	QA	2a4e1d2e-5342-4b46-be3d-80d3a2d9c0dd	1	f	f	\N	0
37cebe78-cf46-4153-be4c-9c2efd8ec04a	Archive	2a4e1d2e-5342-4b46-be3d-80d3a2d9c0dd	3	t	f	\N	0
6cb7e3bd-1710-4eed-8838-d3db60f78f19	New	d61a59e1-a49c-46f2-a929-db2b4bfa88b2	0	f	f	\N	0
ee24a4cb-2d15-4c98-b1bd-6327126451f3	Draft	d61a59e1-a49c-46f2-a929-db2b4bfa88b2	1	f	f	\N	0
dc3c9cd0-8467-404b-bf95-cb7df3fbc293	Published	d61a59e1-a49c-46f2-a929-db2b4bfa88b2	2	t	f	\N	0
d6b095b6-b65f-4bdb-bbfd-701d663dfee2	Archived	d61a59e1-a49c-46f2-a929-db2b4bfa88b2	3	t	f	\N	0
f43c5d5a-fc51-4c67-a750-cc8f8e4a87f7	Published	2a4e1d2e-5342-4b46-be3d-80d3a2d9c0dd	2	f	t	1b84f952-e6c7-40a9-9b8a-06d764d4c8fd	15552000
\.


--
-- Data for Name: workflow_task; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.workflow_task (id, creation_date, mod_date, due_date, created_by, assigned_to, belongs_to, title, description, status, webasset, language_id) FROM stdin;
\.


--
-- Data for Name: workflowtask_files; Type: TABLE DATA; Schema: public; Owner: dotcms_dev
--

COPY public.workflowtask_files (id, workflowtask_id, file_inode) FROM stdin;
\.


--
-- Name: workstream_seq; Type: SEQUENCE SET; Schema: public; Owner: dotcms_dev
--

SELECT pg_catalog.setval('public.workstream_seq', 92, false);


--
-- Name: address address_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.address
    ADD CONSTRAINT address_pkey PRIMARY KEY (addressid);


--
-- Name: adminconfig adminconfig_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.adminconfig
    ADD CONSTRAINT adminconfig_pkey PRIMARY KEY (configid);


--
-- Name: analytic_summary_404 analytic_summary_404_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.analytic_summary_404
    ADD CONSTRAINT analytic_summary_404_pkey PRIMARY KEY (id);


--
-- Name: analytic_summary_content analytic_summary_content_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.analytic_summary_content
    ADD CONSTRAINT analytic_summary_content_pkey PRIMARY KEY (id);


--
-- Name: analytic_summary_pages analytic_summary_pages_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.analytic_summary_pages
    ADD CONSTRAINT analytic_summary_pages_pkey PRIMARY KEY (id);


--
-- Name: analytic_summary_period analytic_summary_period_full_date_key; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.analytic_summary_period
    ADD CONSTRAINT analytic_summary_period_full_date_key UNIQUE (full_date);


--
-- Name: analytic_summary_period analytic_summary_period_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.analytic_summary_period
    ADD CONSTRAINT analytic_summary_period_pkey PRIMARY KEY (id);


--
-- Name: analytic_summary analytic_summary_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.analytic_summary
    ADD CONSTRAINT analytic_summary_pkey PRIMARY KEY (id);


--
-- Name: analytic_summary_referer analytic_summary_referer_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.analytic_summary_referer
    ADD CONSTRAINT analytic_summary_referer_pkey PRIMARY KEY (id);


--
-- Name: analytic_summary analytic_summary_summary_period_id_host_id_key; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.analytic_summary
    ADD CONSTRAINT analytic_summary_summary_period_id_host_id_key UNIQUE (summary_period_id, host_id);


--
-- Name: analytic_summary_visits analytic_summary_visits_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.analytic_summary_visits
    ADD CONSTRAINT analytic_summary_visits_pkey PRIMARY KEY (id);


--
-- Name: analytic_summary_workstream analytic_summary_workstream_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.analytic_summary_workstream
    ADD CONSTRAINT analytic_summary_workstream_pkey PRIMARY KEY (id);


--
-- Name: api_token_issued api_token_issued_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.api_token_issued
    ADD CONSTRAINT api_token_issued_pkey PRIMARY KEY (token_id);


--
-- Name: broken_link broken_link_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.broken_link
    ADD CONSTRAINT broken_link_pkey PRIMARY KEY (id);


--
-- Name: calendar_reminder calendar_reminder_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.calendar_reminder
    ADD CONSTRAINT calendar_reminder_pkey PRIMARY KEY (user_id, event_id, send_date);


--
-- Name: campaign campaign_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.campaign
    ADD CONSTRAINT campaign_pkey PRIMARY KEY (inode);


--
-- Name: category category_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.category
    ADD CONSTRAINT category_pkey PRIMARY KEY (inode);


--
-- Name: chain chain_key_name_key; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.chain
    ADD CONSTRAINT chain_key_name_key UNIQUE (key_name);


--
-- Name: chain_link_code chain_link_code_class_name_key; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.chain_link_code
    ADD CONSTRAINT chain_link_code_class_name_key UNIQUE (class_name);


--
-- Name: chain_link_code chain_link_code_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.chain_link_code
    ADD CONSTRAINT chain_link_code_pkey PRIMARY KEY (id);


--
-- Name: chain chain_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.chain
    ADD CONSTRAINT chain_pkey PRIMARY KEY (id);


--
-- Name: chain_state_parameter chain_state_parameter_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.chain_state_parameter
    ADD CONSTRAINT chain_state_parameter_pkey PRIMARY KEY (id);


--
-- Name: chain_state chain_state_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.chain_state
    ADD CONSTRAINT chain_state_pkey PRIMARY KEY (id);


--
-- Name: challenge_question challenge_question_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.challenge_question
    ADD CONSTRAINT challenge_question_pkey PRIMARY KEY (cquestionid);


--
-- Name: click click_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.click
    ADD CONSTRAINT click_pkey PRIMARY KEY (inode);


--
-- Name: clickstream_404 clickstream_404_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.clickstream_404
    ADD CONSTRAINT clickstream_404_pkey PRIMARY KEY (clickstream_404_id);


--
-- Name: clickstream clickstream_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.clickstream
    ADD CONSTRAINT clickstream_pkey PRIMARY KEY (clickstream_id);


--
-- Name: clickstream_request clickstream_request_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.clickstream_request
    ADD CONSTRAINT clickstream_request_pkey PRIMARY KEY (clickstream_request_id);


--
-- Name: cluster_server_action cluster_server_action_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.cluster_server_action
    ADD CONSTRAINT cluster_server_action_pkey PRIMARY KEY (server_action_id);


--
-- Name: cluster_server cluster_server_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.cluster_server
    ADD CONSTRAINT cluster_server_pkey PRIMARY KEY (server_id);


--
-- Name: cluster_server_uptime cluster_server_uptime_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.cluster_server_uptime
    ADD CONSTRAINT cluster_server_uptime_pkey PRIMARY KEY (id);


--
-- Name: cms_layout cms_layout_name_parent; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.cms_layout
    ADD CONSTRAINT cms_layout_name_parent UNIQUE (layout_name);


--
-- Name: cms_layout cms_layout_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.cms_layout
    ADD CONSTRAINT cms_layout_pkey PRIMARY KEY (id);


--
-- Name: cms_layouts_portlets cms_layouts_portlets_parent1; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.cms_layouts_portlets
    ADD CONSTRAINT cms_layouts_portlets_parent1 UNIQUE (layout_id, portlet_id);


--
-- Name: cms_layouts_portlets cms_layouts_portlets_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.cms_layouts_portlets
    ADD CONSTRAINT cms_layouts_portlets_pkey PRIMARY KEY (id);


--
-- Name: cms_role cms_role_name_db_fqn; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.cms_role
    ADD CONSTRAINT cms_role_name_db_fqn UNIQUE (db_fqn);


--
-- Name: cms_role cms_role_name_role_key; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.cms_role
    ADD CONSTRAINT cms_role_name_role_key UNIQUE (role_key);


--
-- Name: cms_role cms_role_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.cms_role
    ADD CONSTRAINT cms_role_pkey PRIMARY KEY (id);


--
-- Name: cms_roles_ir cms_roles_ir_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.cms_roles_ir
    ADD CONSTRAINT cms_roles_ir_pkey PRIMARY KEY (local_role_id, endpoint_id);


--
-- Name: communication communication_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.communication
    ADD CONSTRAINT communication_pkey PRIMARY KEY (inode);


--
-- Name: company company_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.company
    ADD CONSTRAINT company_pkey PRIMARY KEY (companyid);


--
-- Name: container_structures container_structures_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.container_structures
    ADD CONSTRAINT container_structures_pkey PRIMARY KEY (id);


--
-- Name: container_version_info container_version_info_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.container_version_info
    ADD CONSTRAINT container_version_info_pkey PRIMARY KEY (identifier);


--
-- Name: content_rating content_rating_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.content_rating
    ADD CONSTRAINT content_rating_pkey PRIMARY KEY (id);


--
-- Name: contentlet contentlet_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.contentlet
    ADD CONSTRAINT contentlet_pkey PRIMARY KEY (inode);


--
-- Name: contentlet_version_info contentlet_version_info_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.contentlet_version_info
    ADD CONSTRAINT contentlet_version_info_pkey PRIMARY KEY (identifier, lang);


--
-- Name: counter counter_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.counter
    ADD CONSTRAINT counter_pkey PRIMARY KEY (name);


--
-- Name: dashboard_user_preferences dashboard_user_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.dashboard_user_preferences
    ADD CONSTRAINT dashboard_user_preferences_pkey PRIMARY KEY (id);


--
-- Name: db_version db_version_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.db_version
    ADD CONSTRAINT db_version_pkey PRIMARY KEY (db_version);


--
-- Name: dist_journal dist_journal_object_to_index_key; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.dist_journal
    ADD CONSTRAINT dist_journal_object_to_index_key UNIQUE (object_to_index, serverid, journal_type);


--
-- Name: dist_journal dist_journal_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.dist_journal
    ADD CONSTRAINT dist_journal_pkey PRIMARY KEY (id);


--
-- Name: dist_process dist_process_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.dist_process
    ADD CONSTRAINT dist_process_pkey PRIMARY KEY (id);


--
-- Name: dist_reindex_journal dist_reindex_journal_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.dist_reindex_journal
    ADD CONSTRAINT dist_reindex_journal_pkey PRIMARY KEY (id);


--
-- Name: dot_cluster dot_cluster_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.dot_cluster
    ADD CONSTRAINT dot_cluster_pkey PRIMARY KEY (cluster_id);


--
-- Name: dot_containers dot_containers_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.dot_containers
    ADD CONSTRAINT dot_containers_pkey PRIMARY KEY (inode);


--
-- Name: dot_rule dot_rule_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.dot_rule
    ADD CONSTRAINT dot_rule_pkey PRIMARY KEY (id);


--
-- Name: field field_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.field
    ADD CONSTRAINT field_pkey PRIMARY KEY (inode);


--
-- Name: field_variable field_variable_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.field_variable
    ADD CONSTRAINT field_variable_pkey PRIMARY KEY (id);


--
-- Name: fileassets_ir fileassets_ir_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.fileassets_ir
    ADD CONSTRAINT fileassets_ir_pkey PRIMARY KEY (local_working_inode, language_id, endpoint_id);


--
-- Name: fixes_audit fixes_audit_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.fixes_audit
    ADD CONSTRAINT fixes_audit_pkey PRIMARY KEY (id);


--
-- Name: folder folder_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.folder
    ADD CONSTRAINT folder_pkey PRIMARY KEY (inode);


--
-- Name: folders_ir folders_ir_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.folders_ir
    ADD CONSTRAINT folders_ir_pkey PRIMARY KEY (local_inode, endpoint_id);


--
-- Name: host_variable host_variable_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.host_variable
    ADD CONSTRAINT host_variable_pkey PRIMARY KEY (id);


--
-- Name: htmlpages_ir htmlpages_ir_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.htmlpages_ir
    ADD CONSTRAINT htmlpages_ir_pkey PRIMARY KEY (local_working_inode, language_id, endpoint_id);


--
-- Name: identifier identifier_parent_path_asset_name_host_inode_key; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.identifier
    ADD CONSTRAINT identifier_parent_path_asset_name_host_inode_key UNIQUE (parent_path, asset_name, host_inode);


--
-- Name: identifier identifier_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.identifier
    ADD CONSTRAINT identifier_pkey PRIMARY KEY (id);


--
-- Name: image image_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.image
    ADD CONSTRAINT image_pkey PRIMARY KEY (imageid);


--
-- Name: import_audit import_audit_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.import_audit
    ADD CONSTRAINT import_audit_pkey PRIMARY KEY (id);


--
-- Name: indicies indicies_index_type_key; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.indicies
    ADD CONSTRAINT indicies_index_type_key UNIQUE (index_type);


--
-- Name: indicies indicies_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.indicies
    ADD CONSTRAINT indicies_pkey PRIMARY KEY (index_name);


--
-- Name: inode inode_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.inode
    ADD CONSTRAINT inode_pkey PRIMARY KEY (inode);


--
-- Name: language language_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.language
    ADD CONSTRAINT language_pkey PRIMARY KEY (id);


--
-- Name: layouts_cms_roles layouts_cms_roles_parent1; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.layouts_cms_roles
    ADD CONSTRAINT layouts_cms_roles_parent1 UNIQUE (role_id, layout_id);


--
-- Name: layouts_cms_roles layouts_cms_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.layouts_cms_roles
    ADD CONSTRAINT layouts_cms_roles_pkey PRIMARY KEY (id);


--
-- Name: link_version_info link_version_info_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.link_version_info
    ADD CONSTRAINT link_version_info_pkey PRIMARY KEY (identifier);


--
-- Name: links links_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.links
    ADD CONSTRAINT links_pkey PRIMARY KEY (inode);


--
-- Name: log_mapper log_mapper_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.log_mapper
    ADD CONSTRAINT log_mapper_pkey PRIMARY KEY (log_name);


--
-- Name: mailing_list mailing_list_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.mailing_list
    ADD CONSTRAINT mailing_list_pkey PRIMARY KEY (inode);


--
-- Name: multi_tree multi_tree_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.multi_tree
    ADD CONSTRAINT multi_tree_pkey PRIMARY KEY (child, parent1, parent2, relation_type, personalization);


--
-- Name: passwordtracker passwordtracker_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.passwordtracker
    ADD CONSTRAINT passwordtracker_pkey PRIMARY KEY (passwordtrackerid);


--
-- Name: permission permission_permission_type_inode_id_roleid_key; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.permission
    ADD CONSTRAINT permission_permission_type_inode_id_roleid_key UNIQUE (permission_type, inode_id, roleid);


--
-- Name: permission permission_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.permission
    ADD CONSTRAINT permission_pkey PRIMARY KEY (id);


--
-- Name: permission_reference permission_reference_asset_id_key; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.permission_reference
    ADD CONSTRAINT permission_reference_asset_id_key UNIQUE (asset_id);


--
-- Name: permission_reference permission_reference_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.permission_reference
    ADD CONSTRAINT permission_reference_pkey PRIMARY KEY (id);


--
-- Name: notification pk_notification; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.notification
    ADD CONSTRAINT pk_notification PRIMARY KEY (group_id, user_id);


--
-- Name: system_event pk_system_event; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.system_event
    ADD CONSTRAINT pk_system_event PRIMARY KEY (identifier);


--
-- Name: workflow_action_step pk_workflow_action_step; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.workflow_action_step
    ADD CONSTRAINT pk_workflow_action_step PRIMARY KEY (action_id, step_id);


--
-- Name: plugin plugin_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.plugin
    ADD CONSTRAINT plugin_pkey PRIMARY KEY (id);


--
-- Name: plugin_property plugin_property_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.plugin_property
    ADD CONSTRAINT plugin_property_pkey PRIMARY KEY (plugin_id, propkey);


--
-- Name: pollschoice pollschoice_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.pollschoice
    ADD CONSTRAINT pollschoice_pkey PRIMARY KEY (choiceid, questionid);


--
-- Name: pollsdisplay pollsdisplay_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.pollsdisplay
    ADD CONSTRAINT pollsdisplay_pkey PRIMARY KEY (layoutid, userid, portletid);


--
-- Name: pollsquestion pollsquestion_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.pollsquestion
    ADD CONSTRAINT pollsquestion_pkey PRIMARY KEY (questionid);


--
-- Name: pollsvote pollsvote_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.pollsvote
    ADD CONSTRAINT pollsvote_pkey PRIMARY KEY (questionid, userid);


--
-- Name: portlet portlet_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.portlet
    ADD CONSTRAINT portlet_pkey PRIMARY KEY (portletid, groupid, companyid);


--
-- Name: portlet portlet_role_key; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.portlet
    ADD CONSTRAINT portlet_role_key UNIQUE (portletid);


--
-- Name: portletpreferences portletpreferences_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.portletpreferences
    ADD CONSTRAINT portletpreferences_pkey PRIMARY KEY (portletid, userid, layoutid);


--
-- Name: publishing_bundle_environment publishing_bundle_environment_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.publishing_bundle_environment
    ADD CONSTRAINT publishing_bundle_environment_pkey PRIMARY KEY (id);


--
-- Name: publishing_bundle publishing_bundle_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.publishing_bundle
    ADD CONSTRAINT publishing_bundle_pkey PRIMARY KEY (id);


--
-- Name: publishing_end_point publishing_end_point_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.publishing_end_point
    ADD CONSTRAINT publishing_end_point_pkey PRIMARY KEY (id);


--
-- Name: publishing_end_point publishing_end_point_server_name_key; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.publishing_end_point
    ADD CONSTRAINT publishing_end_point_server_name_key UNIQUE (server_name);


--
-- Name: publishing_environment publishing_environment_name_key; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.publishing_environment
    ADD CONSTRAINT publishing_environment_name_key UNIQUE (name);


--
-- Name: publishing_environment publishing_environment_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.publishing_environment
    ADD CONSTRAINT publishing_environment_pkey PRIMARY KEY (id);


--
-- Name: publishing_queue_audit publishing_queue_audit_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.publishing_queue_audit
    ADD CONSTRAINT publishing_queue_audit_pkey PRIMARY KEY (bundle_id);


--
-- Name: publishing_queue publishing_queue_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.publishing_queue
    ADD CONSTRAINT publishing_queue_pkey PRIMARY KEY (id);


--
-- Name: qrtz_blob_triggers qrtz_blob_triggers_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.qrtz_blob_triggers
    ADD CONSTRAINT qrtz_blob_triggers_pkey PRIMARY KEY (trigger_name, trigger_group);


--
-- Name: qrtz_calendars qrtz_calendars_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.qrtz_calendars
    ADD CONSTRAINT qrtz_calendars_pkey PRIMARY KEY (calendar_name);


--
-- Name: qrtz_cron_triggers qrtz_cron_triggers_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.qrtz_cron_triggers
    ADD CONSTRAINT qrtz_cron_triggers_pkey PRIMARY KEY (trigger_name, trigger_group);


--
-- Name: qrtz_excl_blob_triggers qrtz_excl_blob_triggers_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.qrtz_excl_blob_triggers
    ADD CONSTRAINT qrtz_excl_blob_triggers_pkey PRIMARY KEY (trigger_name, trigger_group);


--
-- Name: qrtz_excl_calendars qrtz_excl_calendars_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.qrtz_excl_calendars
    ADD CONSTRAINT qrtz_excl_calendars_pkey PRIMARY KEY (calendar_name);


--
-- Name: qrtz_excl_cron_triggers qrtz_excl_cron_triggers_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.qrtz_excl_cron_triggers
    ADD CONSTRAINT qrtz_excl_cron_triggers_pkey PRIMARY KEY (trigger_name, trigger_group);


--
-- Name: qrtz_excl_fired_triggers qrtz_excl_fired_triggers_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.qrtz_excl_fired_triggers
    ADD CONSTRAINT qrtz_excl_fired_triggers_pkey PRIMARY KEY (entry_id);


--
-- Name: qrtz_excl_job_details qrtz_excl_job_details_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.qrtz_excl_job_details
    ADD CONSTRAINT qrtz_excl_job_details_pkey PRIMARY KEY (job_name, job_group);


--
-- Name: qrtz_excl_job_listeners qrtz_excl_job_listeners_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.qrtz_excl_job_listeners
    ADD CONSTRAINT qrtz_excl_job_listeners_pkey PRIMARY KEY (job_name, job_group, job_listener);


--
-- Name: qrtz_excl_locks qrtz_excl_locks_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.qrtz_excl_locks
    ADD CONSTRAINT qrtz_excl_locks_pkey PRIMARY KEY (lock_name);


--
-- Name: qrtz_excl_paused_trigger_grps qrtz_excl_paused_trigger_grps_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.qrtz_excl_paused_trigger_grps
    ADD CONSTRAINT qrtz_excl_paused_trigger_grps_pkey PRIMARY KEY (trigger_group);


--
-- Name: qrtz_excl_scheduler_state qrtz_excl_scheduler_state_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.qrtz_excl_scheduler_state
    ADD CONSTRAINT qrtz_excl_scheduler_state_pkey PRIMARY KEY (instance_name);


--
-- Name: qrtz_excl_simple_triggers qrtz_excl_simple_triggers_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.qrtz_excl_simple_triggers
    ADD CONSTRAINT qrtz_excl_simple_triggers_pkey PRIMARY KEY (trigger_name, trigger_group);


--
-- Name: qrtz_excl_trigger_listeners qrtz_excl_trigger_listeners_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.qrtz_excl_trigger_listeners
    ADD CONSTRAINT qrtz_excl_trigger_listeners_pkey PRIMARY KEY (trigger_name, trigger_group, trigger_listener);


--
-- Name: qrtz_excl_triggers qrtz_excl_triggers_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.qrtz_excl_triggers
    ADD CONSTRAINT qrtz_excl_triggers_pkey PRIMARY KEY (trigger_name, trigger_group);


--
-- Name: qrtz_fired_triggers qrtz_fired_triggers_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.qrtz_fired_triggers
    ADD CONSTRAINT qrtz_fired_triggers_pkey PRIMARY KEY (entry_id);


--
-- Name: qrtz_job_details qrtz_job_details_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.qrtz_job_details
    ADD CONSTRAINT qrtz_job_details_pkey PRIMARY KEY (job_name, job_group);


--
-- Name: qrtz_job_listeners qrtz_job_listeners_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.qrtz_job_listeners
    ADD CONSTRAINT qrtz_job_listeners_pkey PRIMARY KEY (job_name, job_group, job_listener);


--
-- Name: qrtz_locks qrtz_locks_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.qrtz_locks
    ADD CONSTRAINT qrtz_locks_pkey PRIMARY KEY (lock_name);


--
-- Name: qrtz_paused_trigger_grps qrtz_paused_trigger_grps_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.qrtz_paused_trigger_grps
    ADD CONSTRAINT qrtz_paused_trigger_grps_pkey PRIMARY KEY (trigger_group);


--
-- Name: qrtz_scheduler_state qrtz_scheduler_state_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.qrtz_scheduler_state
    ADD CONSTRAINT qrtz_scheduler_state_pkey PRIMARY KEY (instance_name);


--
-- Name: qrtz_simple_triggers qrtz_simple_triggers_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.qrtz_simple_triggers
    ADD CONSTRAINT qrtz_simple_triggers_pkey PRIMARY KEY (trigger_name, trigger_group);


--
-- Name: qrtz_trigger_listeners qrtz_trigger_listeners_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.qrtz_trigger_listeners
    ADD CONSTRAINT qrtz_trigger_listeners_pkey PRIMARY KEY (trigger_name, trigger_group, trigger_listener);


--
-- Name: qrtz_triggers qrtz_triggers_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.qrtz_triggers
    ADD CONSTRAINT qrtz_triggers_pkey PRIMARY KEY (trigger_name, trigger_group);


--
-- Name: quartz_log quartz_log_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.quartz_log
    ADD CONSTRAINT quartz_log_pkey PRIMARY KEY (id);


--
-- Name: recipient recipient_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.recipient
    ADD CONSTRAINT recipient_pkey PRIMARY KEY (inode);


--
-- Name: relationship relationship_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.relationship
    ADD CONSTRAINT relationship_pkey PRIMARY KEY (inode);


--
-- Name: relationship relationship_relation_type_value_key; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.relationship
    ADD CONSTRAINT relationship_relation_type_value_key UNIQUE (relation_type_value);


--
-- Name: release_ release__pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.release_
    ADD CONSTRAINT release__pkey PRIMARY KEY (releaseid);


--
-- Name: report_asset report_asset_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.report_asset
    ADD CONSTRAINT report_asset_pkey PRIMARY KEY (inode);


--
-- Name: report_parameter report_parameter_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.report_parameter
    ADD CONSTRAINT report_parameter_pkey PRIMARY KEY (inode);


--
-- Name: report_parameter report_parameter_report_inode_parameter_name_key; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.report_parameter
    ADD CONSTRAINT report_parameter_report_inode_parameter_name_key UNIQUE (report_inode, parameter_name);


--
-- Name: rule_action_pars rule_action_pars_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.rule_action_pars
    ADD CONSTRAINT rule_action_pars_pkey PRIMARY KEY (id);


--
-- Name: rule_action rule_action_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.rule_action
    ADD CONSTRAINT rule_action_pkey PRIMARY KEY (id);


--
-- Name: rule_condition_group rule_condition_group_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.rule_condition_group
    ADD CONSTRAINT rule_condition_group_pkey PRIMARY KEY (id);


--
-- Name: rule_condition rule_condition_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.rule_condition
    ADD CONSTRAINT rule_condition_pkey PRIMARY KEY (id);


--
-- Name: rule_condition_value rule_condition_value_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.rule_condition_value
    ADD CONSTRAINT rule_condition_value_pkey PRIMARY KEY (id);


--
-- Name: schemes_ir schemes_ir_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.schemes_ir
    ADD CONSTRAINT schemes_ir_pkey PRIMARY KEY (local_inode, endpoint_id);


--
-- Name: sitelic sitelic_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.sitelic
    ADD CONSTRAINT sitelic_pkey PRIMARY KEY (id);


--
-- Name: sitesearch_audit sitesearch_audit_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.sitesearch_audit
    ADD CONSTRAINT sitesearch_audit_pkey PRIMARY KEY (job_id, fire_date);


--
-- Name: structure structure_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.structure
    ADD CONSTRAINT structure_pkey PRIMARY KEY (inode);


--
-- Name: structures_ir structures_ir_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.structures_ir
    ADD CONSTRAINT structures_ir_pkey PRIMARY KEY (local_inode, endpoint_id);


--
-- Name: tag_inode tag_inode_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.tag_inode
    ADD CONSTRAINT tag_inode_pkey PRIMARY KEY (tag_id, inode);


--
-- Name: tag tag_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.tag
    ADD CONSTRAINT tag_pkey PRIMARY KEY (tag_id);


--
-- Name: tag tag_tagname_host; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.tag
    ADD CONSTRAINT tag_tagname_host UNIQUE (tagname, host_id);


--
-- Name: template_containers template_containers_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.template_containers
    ADD CONSTRAINT template_containers_pkey PRIMARY KEY (id);


--
-- Name: template template_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.template
    ADD CONSTRAINT template_pkey PRIMARY KEY (inode);


--
-- Name: template_version_info template_version_info_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.template_version_info
    ADD CONSTRAINT template_version_info_pkey PRIMARY KEY (identifier);


--
-- Name: trackback trackback_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.trackback
    ADD CONSTRAINT trackback_pkey PRIMARY KEY (id);


--
-- Name: tree tree_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.tree
    ADD CONSTRAINT tree_pkey PRIMARY KEY (child, parent, relation_type);


--
-- Name: structure unique_struct_vel_var_name; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.structure
    ADD CONSTRAINT unique_struct_vel_var_name UNIQUE (velocity_var_name);


--
-- Name: workflow_task unique_workflow_task; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.workflow_task
    ADD CONSTRAINT unique_workflow_task UNIQUE (webasset, language_id);


--
-- Name: user_ user__pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.user_
    ADD CONSTRAINT user__pkey PRIMARY KEY (userid);


--
-- Name: user_comments user_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.user_comments
    ADD CONSTRAINT user_comments_pkey PRIMARY KEY (inode);


--
-- Name: user_filter user_filter_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.user_filter
    ADD CONSTRAINT user_filter_pkey PRIMARY KEY (inode);


--
-- Name: user_preferences user_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.user_preferences
    ADD CONSTRAINT user_preferences_pkey PRIMARY KEY (id);


--
-- Name: user_proxy user_proxy_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.user_proxy
    ADD CONSTRAINT user_proxy_pkey PRIMARY KEY (inode);


--
-- Name: user_proxy user_proxy_user_id_key; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.user_proxy
    ADD CONSTRAINT user_proxy_user_id_key UNIQUE (user_id);


--
-- Name: users_cms_roles users_cms_roles_parent1; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.users_cms_roles
    ADD CONSTRAINT users_cms_roles_parent1 UNIQUE (role_id, user_id);


--
-- Name: users_cms_roles users_cms_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.users_cms_roles
    ADD CONSTRAINT users_cms_roles_pkey PRIMARY KEY (id);


--
-- Name: users_to_delete users_to_delete_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.users_to_delete
    ADD CONSTRAINT users_to_delete_pkey PRIMARY KEY (id);


--
-- Name: usertracker usertracker_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.usertracker
    ADD CONSTRAINT usertracker_pkey PRIMARY KEY (usertrackerid);


--
-- Name: usertrackerpath usertrackerpath_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.usertrackerpath
    ADD CONSTRAINT usertrackerpath_pkey PRIMARY KEY (usertrackerpathid);


--
-- Name: web_form web_form_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.web_form
    ADD CONSTRAINT web_form_pkey PRIMARY KEY (web_form_id);


--
-- Name: workflow_action_class_pars workflow_action_class_pars_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.workflow_action_class_pars
    ADD CONSTRAINT workflow_action_class_pars_pkey PRIMARY KEY (id);


--
-- Name: workflow_action_class workflow_action_class_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.workflow_action_class
    ADD CONSTRAINT workflow_action_class_pkey PRIMARY KEY (id);


--
-- Name: workflow_action_mappings workflow_action_mappings_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.workflow_action_mappings
    ADD CONSTRAINT workflow_action_mappings_pkey PRIMARY KEY (id);


--
-- Name: workflow_action workflow_action_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.workflow_action
    ADD CONSTRAINT workflow_action_pkey PRIMARY KEY (id);


--
-- Name: workflow_comment workflow_comment_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.workflow_comment
    ADD CONSTRAINT workflow_comment_pkey PRIMARY KEY (id);


--
-- Name: workflow_history workflow_history_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.workflow_history
    ADD CONSTRAINT workflow_history_pkey PRIMARY KEY (id);


--
-- Name: workflow_scheme workflow_scheme_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.workflow_scheme
    ADD CONSTRAINT workflow_scheme_pkey PRIMARY KEY (id);


--
-- Name: workflow_scheme_x_structure workflow_scheme_x_structure_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.workflow_scheme_x_structure
    ADD CONSTRAINT workflow_scheme_x_structure_pkey PRIMARY KEY (id);


--
-- Name: workflow_step workflow_step_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.workflow_step
    ADD CONSTRAINT workflow_step_pkey PRIMARY KEY (id);


--
-- Name: workflow_task workflow_task_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.workflow_task
    ADD CONSTRAINT workflow_task_pkey PRIMARY KEY (id);


--
-- Name: workflowtask_files workflowtask_files_pkey; Type: CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.workflowtask_files
    ADD CONSTRAINT workflowtask_files_pkey PRIMARY KEY (id);


--
-- Name: addres_userid_index; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX addres_userid_index ON public.address USING btree (userid);


--
-- Name: containers_ident; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX containers_ident ON public.dot_containers USING btree (identifier);


--
-- Name: contentlet_ident; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX contentlet_ident ON public.contentlet USING btree (identifier);


--
-- Name: contentlet_lang; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX contentlet_lang ON public.contentlet USING btree (language_id);


--
-- Name: contentlet_moduser; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX contentlet_moduser ON public.contentlet USING btree (mod_user);


--
-- Name: dist_process_index; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX dist_process_index ON public.dist_process USING btree (object_to_index, serverid, journal_type);


--
-- Name: dist_reindex_index; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX dist_reindex_index ON public.dist_reindex_journal USING btree (serverid, dist_action);


--
-- Name: dist_reindex_index1; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX dist_reindex_index1 ON public.dist_reindex_journal USING btree (inode_to_index);


--
-- Name: dist_reindex_index2; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX dist_reindex_index2 ON public.dist_reindex_journal USING btree (dist_action);


--
-- Name: dist_reindex_index3; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX dist_reindex_index3 ON public.dist_reindex_journal USING btree (serverid);


--
-- Name: dist_reindex_index4; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX dist_reindex_index4 ON public.dist_reindex_journal USING btree (ident_to_index, serverid);


--
-- Name: dist_reindex_index5; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX dist_reindex_index5 ON public.dist_reindex_journal USING btree (priority, time_entered);


--
-- Name: dist_reindex_index6; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX dist_reindex_index6 ON public.dist_reindex_journal USING btree (priority);


--
-- Name: folder_ident; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX folder_ident ON public.folder USING btree (identifier);


--
-- Name: idx_analytic_summary_1; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_analytic_summary_1 ON public.analytic_summary USING btree (host_id);


--
-- Name: idx_analytic_summary_2; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_analytic_summary_2 ON public.analytic_summary USING btree (visits);


--
-- Name: idx_analytic_summary_3; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_analytic_summary_3 ON public.analytic_summary USING btree (page_views);


--
-- Name: idx_analytic_summary_404_1; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_analytic_summary_404_1 ON public.analytic_summary_404 USING btree (host_id);


--
-- Name: idx_analytic_summary_period_2; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_analytic_summary_period_2 ON public.analytic_summary_period USING btree (day);


--
-- Name: idx_analytic_summary_period_3; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_analytic_summary_period_3 ON public.analytic_summary_period USING btree (week);


--
-- Name: idx_analytic_summary_period_4; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_analytic_summary_period_4 ON public.analytic_summary_period USING btree (month);


--
-- Name: idx_analytic_summary_period_5; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_analytic_summary_period_5 ON public.analytic_summary_period USING btree (year);


--
-- Name: idx_analytic_summary_visits_1; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_analytic_summary_visits_1 ON public.analytic_summary_visits USING btree (host_id);


--
-- Name: idx_analytic_summary_visits_2; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_analytic_summary_visits_2 ON public.analytic_summary_visits USING btree (visit_time);


--
-- Name: idx_api_token_issued_user; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_api_token_issued_user ON public.api_token_issued USING btree (token_userid);


--
-- Name: idx_campaign_1; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_campaign_1 ON public.campaign USING btree (user_id);


--
-- Name: idx_campaign_2; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_campaign_2 ON public.campaign USING btree (start_date);


--
-- Name: idx_campaign_3; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_campaign_3 ON public.campaign USING btree (completed_date);


--
-- Name: idx_campaign_4; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_campaign_4 ON public.campaign USING btree (expiration_date);


--
-- Name: idx_category_1; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_category_1 ON public.category USING btree (category_name);


--
-- Name: idx_category_2; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_category_2 ON public.category USING btree (category_key);


--
-- Name: idx_chain_key_name; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_chain_key_name ON public.chain USING btree (key_name);


--
-- Name: idx_chain_link_code_classname; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_chain_link_code_classname ON public.chain_link_code USING btree (class_name);


--
-- Name: idx_click_1; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_click_1 ON public.click USING btree (link);


--
-- Name: idx_communication_user_id; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_communication_user_id ON public.recipient USING btree (user_id);


--
-- Name: idx_container_id; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_container_id ON public.container_structures USING btree (container_id);


--
-- Name: idx_container_vi_live; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_container_vi_live ON public.container_version_info USING btree (live_inode);


--
-- Name: idx_container_vi_version_ts; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_container_vi_version_ts ON public.container_version_info USING btree (version_ts);


--
-- Name: idx_container_vi_working; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_container_vi_working ON public.container_version_info USING btree (working_inode);


--
-- Name: idx_contentlet_3; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_contentlet_3 ON public.contentlet USING btree (inode);


--
-- Name: idx_contentlet_4; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_contentlet_4 ON public.contentlet USING btree (structure_inode);


--
-- Name: idx_contentlet_identifier; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_contentlet_identifier ON public.contentlet USING btree (identifier);


--
-- Name: idx_contentlet_vi_live; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_contentlet_vi_live ON public.contentlet_version_info USING btree (live_inode);


--
-- Name: idx_contentlet_vi_version_ts; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_contentlet_vi_version_ts ON public.contentlet_version_info USING btree (version_ts);


--
-- Name: idx_contentlet_vi_working; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_contentlet_vi_working ON public.contentlet_version_info USING btree (working_inode);


--
-- Name: idx_dashboard_prefs_2; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_dashboard_prefs_2 ON public.dashboard_user_preferences USING btree (user_id);


--
-- Name: idx_dashboard_workstream_1; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_dashboard_workstream_1 ON public.analytic_summary_workstream USING btree (mod_user_id);


--
-- Name: idx_dashboard_workstream_2; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_dashboard_workstream_2 ON public.analytic_summary_workstream USING btree (host_id);


--
-- Name: idx_dashboard_workstream_3; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_dashboard_workstream_3 ON public.analytic_summary_workstream USING btree (mod_date);


--
-- Name: idx_field_1; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_field_1 ON public.field USING btree (structure_inode);


--
-- Name: idx_field_velocity_structure; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE UNIQUE INDEX idx_field_velocity_structure ON public.field USING btree (velocity_var_name, structure_inode);


--
-- Name: idx_folder_1; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_folder_1 ON public.folder USING btree (name);


--
-- Name: idx_ident_uniq_asset_name; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE UNIQUE INDEX idx_ident_uniq_asset_name ON public.identifier USING btree (public.full_path_lc(identifier.*), host_inode);


--
-- Name: idx_identifier; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_identifier ON public.identifier USING btree (id);


--
-- Name: idx_identifier_exp; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_identifier_exp ON public.identifier USING btree (sysexpire_date);


--
-- Name: idx_identifier_perm; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_identifier_perm ON public.identifier USING btree (asset_type, host_inode);


--
-- Name: idx_identifier_pub; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_identifier_pub ON public.identifier USING btree (syspublish_date);


--
-- Name: idx_index_1; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_index_1 ON public.inode USING btree (type);


--
-- Name: idx_link_vi_live; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_link_vi_live ON public.link_version_info USING btree (live_inode);


--
-- Name: idx_link_vi_version_ts; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_link_vi_version_ts ON public.link_version_info USING btree (version_ts);


--
-- Name: idx_link_vi_working; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_link_vi_working ON public.link_version_info USING btree (working_inode);


--
-- Name: idx_lower_structure_name; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_lower_structure_name ON public.structure USING btree (lower((velocity_var_name)::text));


--
-- Name: idx_mailinglist_1; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_mailinglist_1 ON public.mailing_list USING btree (user_id);


--
-- Name: idx_multitree_1; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_multitree_1 ON public.multi_tree USING btree (relation_type);


--
-- Name: idx_not_read; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_not_read ON public.notification USING btree (was_read);


--
-- Name: idx_permisision_4; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_permisision_4 ON public.permission USING btree (permission_type);


--
-- Name: idx_permission_2; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_permission_2 ON public.permission USING btree (permission_type, inode_id);


--
-- Name: idx_permission_3; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_permission_3 ON public.permission USING btree (roleid);


--
-- Name: idx_permission_reference_2; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_permission_reference_2 ON public.permission_reference USING btree (reference_id);


--
-- Name: idx_permission_reference_3; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_permission_reference_3 ON public.permission_reference USING btree (reference_id, permission_type);


--
-- Name: idx_permission_reference_4; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_permission_reference_4 ON public.permission_reference USING btree (asset_id, permission_type);


--
-- Name: idx_permission_reference_5; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_permission_reference_5 ON public.permission_reference USING btree (asset_id, reference_id, permission_type);


--
-- Name: idx_permission_reference_6; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_permission_reference_6 ON public.permission_reference USING btree (permission_type);


--
-- Name: idx_preference_1; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_preference_1 ON public.user_preferences USING btree (preference);


--
-- Name: idx_pub_qa_1; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_pub_qa_1 ON public.publishing_queue_audit USING btree (status);


--
-- Name: idx_pushed_assets_1; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_pushed_assets_1 ON public.publishing_pushed_assets USING btree (bundle_id);


--
-- Name: idx_pushed_assets_2; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_pushed_assets_2 ON public.publishing_pushed_assets USING btree (environment_id);


--
-- Name: idx_pushed_assets_3; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_pushed_assets_3 ON public.publishing_pushed_assets USING btree (asset_id, environment_id);


--
-- Name: idx_recipiets_1; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_recipiets_1 ON public.recipient USING btree (email);


--
-- Name: idx_recipiets_2; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_recipiets_2 ON public.recipient USING btree (sent);


--
-- Name: idx_relationship_1; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_relationship_1 ON public.relationship USING btree (parent_structure_inode);


--
-- Name: idx_relationship_2; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_relationship_2 ON public.relationship USING btree (child_structure_inode);


--
-- Name: idx_rules_fire_on; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_rules_fire_on ON public.dot_rule USING btree (fire_on);


--
-- Name: idx_structure_folder; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_structure_folder ON public.structure USING btree (folder);


--
-- Name: idx_structure_host; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_structure_host ON public.structure USING btree (host);


--
-- Name: idx_system_event; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_system_event ON public.system_event USING btree (created);


--
-- Name: idx_template3; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_template3 ON public.template USING btree (lower((title)::text));


--
-- Name: idx_template_id; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_template_id ON public.template_containers USING btree (template_id);


--
-- Name: idx_template_vi_live; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_template_vi_live ON public.template_version_info USING btree (live_inode);


--
-- Name: idx_template_vi_version_ts; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_template_vi_version_ts ON public.template_version_info USING btree (version_ts);


--
-- Name: idx_template_vi_working; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_template_vi_working ON public.template_version_info USING btree (working_inode);


--
-- Name: idx_trackback_1; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_trackback_1 ON public.trackback USING btree (asset_identifier);


--
-- Name: idx_trackback_2; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_trackback_2 ON public.trackback USING btree (url);


--
-- Name: idx_tree; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_tree ON public.tree USING btree (child, parent, relation_type);


--
-- Name: idx_tree_1; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_tree_1 ON public.tree USING btree (parent);


--
-- Name: idx_tree_2; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_tree_2 ON public.tree USING btree (child);


--
-- Name: idx_tree_3; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_tree_3 ON public.tree USING btree (relation_type);


--
-- Name: idx_tree_4; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_tree_4 ON public.tree USING btree (parent, child, relation_type);


--
-- Name: idx_tree_5; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_tree_5 ON public.tree USING btree (parent, relation_type);


--
-- Name: idx_tree_6; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_tree_6 ON public.tree USING btree (child, relation_type);


--
-- Name: idx_user_clickstream11; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_user_clickstream11 ON public.clickstream USING btree (host_id);


--
-- Name: idx_user_clickstream12; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_user_clickstream12 ON public.clickstream USING btree (last_page_id);


--
-- Name: idx_user_clickstream13; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_user_clickstream13 ON public.clickstream USING btree (first_page_id);


--
-- Name: idx_user_clickstream14; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_user_clickstream14 ON public.clickstream USING btree (operating_system);


--
-- Name: idx_user_clickstream15; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_user_clickstream15 ON public.clickstream USING btree (browser_name);


--
-- Name: idx_user_clickstream16; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_user_clickstream16 ON public.clickstream USING btree (browser_version);


--
-- Name: idx_user_clickstream17; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_user_clickstream17 ON public.clickstream USING btree (remote_address);


--
-- Name: idx_user_clickstream_1; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_user_clickstream_1 ON public.clickstream USING btree (cookie_id);


--
-- Name: idx_user_clickstream_2; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_user_clickstream_2 ON public.clickstream USING btree (user_id);


--
-- Name: idx_user_clickstream_404_1; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_user_clickstream_404_1 ON public.clickstream_404 USING btree (request_uri);


--
-- Name: idx_user_clickstream_404_2; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_user_clickstream_404_2 ON public.clickstream_404 USING btree (user_id);


--
-- Name: idx_user_clickstream_404_3; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_user_clickstream_404_3 ON public.clickstream_404 USING btree (host_id);


--
-- Name: idx_user_clickstream_request_1; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_user_clickstream_request_1 ON public.clickstream_request USING btree (clickstream_id);


--
-- Name: idx_user_clickstream_request_2; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_user_clickstream_request_2 ON public.clickstream_request USING btree (request_uri);


--
-- Name: idx_user_clickstream_request_3; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_user_clickstream_request_3 ON public.clickstream_request USING btree (associated_identifier);


--
-- Name: idx_user_clickstream_request_4; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_user_clickstream_request_4 ON public.clickstream_request USING btree (timestampper);


--
-- Name: idx_user_comments_1; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_user_comments_1 ON public.user_comments USING btree (user_id);


--
-- Name: idx_user_webform_1; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_user_webform_1 ON public.web_form USING btree (form_type);


--
-- Name: idx_workflow_1; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_workflow_1 ON public.workflow_task USING btree (assigned_to);


--
-- Name: idx_workflow_2; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_workflow_2 ON public.workflow_task USING btree (belongs_to);


--
-- Name: idx_workflow_3; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_workflow_3 ON public.workflow_task USING btree (status);


--
-- Name: idx_workflow_4; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_workflow_4 ON public.workflow_task USING btree (webasset);


--
-- Name: idx_workflow_5; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_workflow_5 ON public.workflow_task USING btree (created_by);


--
-- Name: idx_workflow_6; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX idx_workflow_6 ON public.workflow_task USING btree (language_id);


--
-- Name: idx_workflow_action_mappings; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE UNIQUE INDEX idx_workflow_action_mappings ON public.workflow_action_mappings USING btree (action, workflow_action, scheme_or_content_type);


--
-- Name: links_ident; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX links_ident ON public.links USING btree (identifier);


--
-- Name: tag_inode_inode; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX tag_inode_inode ON public.tag_inode USING btree (inode);


--
-- Name: tag_inode_tagid; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX tag_inode_tagid ON public.tag_inode USING btree (tag_id);


--
-- Name: tag_is_persona_index; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX tag_is_persona_index ON public.tag USING btree (persona);


--
-- Name: tag_user_id_index; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX tag_user_id_index ON public.tag USING btree (user_id);


--
-- Name: template_ident; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX template_ident ON public.template USING btree (identifier);


--
-- Name: workflow_idx_action_class_action; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX workflow_idx_action_class_action ON public.workflow_action_class USING btree (action_id);


--
-- Name: workflow_idx_action_class_param_action; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX workflow_idx_action_class_param_action ON public.workflow_action_class_pars USING btree (workflow_action_class_id);


--
-- Name: workflow_idx_step_scheme; Type: INDEX; Schema: public; Owner: dotcms_dev
--

CREATE INDEX workflow_idx_step_scheme ON public.workflow_step USING btree (scheme_id);


--
-- Name: identifier check_child_assets_trigger; Type: TRIGGER; Schema: public; Owner: dotcms_dev
--

CREATE TRIGGER check_child_assets_trigger BEFORE DELETE ON public.identifier FOR EACH ROW EXECUTE PROCEDURE public.check_child_assets();


--
-- Name: dot_containers container_versions_check_trigger; Type: TRIGGER; Schema: public; Owner: dotcms_dev
--

CREATE TRIGGER container_versions_check_trigger AFTER DELETE ON public.dot_containers FOR EACH ROW EXECUTE PROCEDURE public.container_versions_check();


--
-- Name: contentlet content_versions_check_trigger; Type: TRIGGER; Schema: public; Owner: dotcms_dev
--

CREATE TRIGGER content_versions_check_trigger AFTER DELETE ON public.contentlet FOR EACH ROW EXECUTE PROCEDURE public.content_versions_check();


--
-- Name: folder folder_identifier_check_trigger; Type: TRIGGER; Schema: public; Owner: dotcms_dev
--

CREATE TRIGGER folder_identifier_check_trigger AFTER DELETE ON public.folder FOR EACH ROW EXECUTE PROCEDURE public.folder_identifier_check();


--
-- Name: identifier identifier_parent_path_trigger; Type: TRIGGER; Schema: public; Owner: dotcms_dev
--

CREATE TRIGGER identifier_parent_path_trigger BEFORE INSERT OR UPDATE ON public.identifier FOR EACH ROW EXECUTE PROCEDURE public.identifier_parent_path_check();


--
-- Name: links link_versions_check_trigger; Type: TRIGGER; Schema: public; Owner: dotcms_dev
--

CREATE TRIGGER link_versions_check_trigger AFTER DELETE ON public.links FOR EACH ROW EXECUTE PROCEDURE public.link_versions_check();


--
-- Name: folder rename_folder_assets_trigger; Type: TRIGGER; Schema: public; Owner: dotcms_dev
--

CREATE TRIGGER rename_folder_assets_trigger AFTER UPDATE ON public.folder FOR EACH ROW EXECUTE PROCEDURE public.rename_folder_and_assets();


--
-- Name: identifier required_identifier_host_inode_trigger; Type: TRIGGER; Schema: public; Owner: dotcms_dev
--

CREATE TRIGGER required_identifier_host_inode_trigger BEFORE INSERT OR UPDATE ON public.identifier FOR EACH ROW EXECUTE PROCEDURE public.identifier_host_inode_check();


--
-- Name: structure structure_host_folder_trigger; Type: TRIGGER; Schema: public; Owner: dotcms_dev
--

CREATE TRIGGER structure_host_folder_trigger BEFORE INSERT OR UPDATE ON public.structure FOR EACH ROW EXECUTE PROCEDURE public.structure_host_folder_check();


--
-- Name: template template_versions_check_trigger; Type: TRIGGER; Schema: public; Owner: dotcms_dev
--

CREATE TRIGGER template_versions_check_trigger AFTER DELETE ON public.template FOR EACH ROW EXECUTE PROCEDURE public.template_versions_check();


--
-- Name: cluster_server_uptime cluster_server_uptime_server_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.cluster_server_uptime
    ADD CONSTRAINT cluster_server_uptime_server_id_fkey FOREIGN KEY (server_id) REFERENCES public.cluster_server(server_id);


--
-- Name: dot_containers containers_identifier_fk; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.dot_containers
    ADD CONSTRAINT containers_identifier_fk FOREIGN KEY (identifier) REFERENCES public.identifier(id);


--
-- Name: contentlet content_identifier_fk; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.contentlet
    ADD CONSTRAINT content_identifier_fk FOREIGN KEY (identifier) REFERENCES public.identifier(id);


--
-- Name: report_parameter fk22da125e5fb51eb; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.report_parameter
    ADD CONSTRAINT fk22da125e5fb51eb FOREIGN KEY (inode) REFERENCES public.inode(inode);


--
-- Name: category fk302bcfe5fb51eb; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.category
    ADD CONSTRAINT fk302bcfe5fb51eb FOREIGN KEY (inode) REFERENCES public.inode(inode);


--
-- Name: recipient fk30e172195fb51eb; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.recipient
    ADD CONSTRAINT fk30e172195fb51eb FOREIGN KEY (inode) REFERENCES public.inode(inode);


--
-- Name: report_asset fk3765ec255fb51eb; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.report_asset
    ADD CONSTRAINT fk3765ec255fb51eb FOREIGN KEY (inode) REFERENCES public.inode(inode);


--
-- Name: dashboard_user_preferences fk496242cfd12c0c3b; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.dashboard_user_preferences
    ADD CONSTRAINT fk496242cfd12c0c3b FOREIGN KEY (summary_404_id) REFERENCES public.analytic_summary_404(id);


--
-- Name: analytic_summary_content fk53cb4f2eed30e054; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.analytic_summary_content
    ADD CONSTRAINT fk53cb4f2eed30e054 FOREIGN KEY (summary_id) REFERENCES public.analytic_summary(id);


--
-- Name: click fk5a5c5885fb51eb; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.click
    ADD CONSTRAINT fk5a5c5885fb51eb FOREIGN KEY (inode) REFERENCES public.inode(inode);


--
-- Name: analytic_summary_referer fk5bc0f3e2ed30e054; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.analytic_summary_referer
    ADD CONSTRAINT fk5bc0f3e2ed30e054 FOREIGN KEY (summary_id) REFERENCES public.analytic_summary(id);


--
-- Name: field fk5cea0fa5fb51eb; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.field
    ADD CONSTRAINT fk5cea0fa5fb51eb FOREIGN KEY (inode) REFERENCES public.inode(inode);


--
-- Name: links fk6234fb95fb51eb; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.links
    ADD CONSTRAINT fk6234fb95fb51eb FOREIGN KEY (inode) REFERENCES public.inode(inode);


--
-- Name: analytic_summary_404 fk7050866db7b46300; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.analytic_summary_404
    ADD CONSTRAINT fk7050866db7b46300 FOREIGN KEY (summary_period_id) REFERENCES public.analytic_summary_period(id);


--
-- Name: user_proxy fk7327d4fa5fb51eb; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.user_proxy
    ADD CONSTRAINT fk7327d4fa5fb51eb FOREIGN KEY (inode) REFERENCES public.inode(inode);


--
-- Name: mailing_list fk7bc2cd925fb51eb; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.mailing_list
    ADD CONSTRAINT fk7bc2cd925fb51eb FOREIGN KEY (inode) REFERENCES public.inode(inode);


--
-- Name: structure fk89d2d735fb51eb; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.structure
    ADD CONSTRAINT fk89d2d735fb51eb FOREIGN KEY (inode) REFERENCES public.inode(inode);


--
-- Name: dot_containers fk8a844125fb51eb; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.dot_containers
    ADD CONSTRAINT fk8a844125fb51eb FOREIGN KEY (inode) REFERENCES public.inode(inode);


--
-- Name: analytic_summary fk9e1a7f4b7b46300; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.analytic_summary
    ADD CONSTRAINT fk9e1a7f4b7b46300 FOREIGN KEY (summary_period_id) REFERENCES public.analytic_summary_period(id);


--
-- Name: analytic_summary_visits fk9eac9733b7b46300; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.analytic_summary_visits
    ADD CONSTRAINT fk9eac9733b7b46300 FOREIGN KEY (summary_period_id) REFERENCES public.analytic_summary_period(id);


--
-- Name: broken_link fk_brokenl_content; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.broken_link
    ADD CONSTRAINT fk_brokenl_content FOREIGN KEY (inode) REFERENCES public.contentlet(inode) ON DELETE CASCADE;


--
-- Name: broken_link fk_brokenl_field; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.broken_link
    ADD CONSTRAINT fk_brokenl_field FOREIGN KEY (field) REFERENCES public.field(inode) ON DELETE CASCADE;


--
-- Name: publishing_bundle_environment fk_bundle_id; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.publishing_bundle_environment
    ADD CONSTRAINT fk_bundle_id FOREIGN KEY (bundle_id) REFERENCES public.publishing_bundle(id);


--
-- Name: cluster_server fk_cluster_id; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.cluster_server
    ADD CONSTRAINT fk_cluster_id FOREIGN KEY (cluster_id) REFERENCES public.dot_cluster(cluster_id);


--
-- Name: cluster_server_uptime fk_cluster_server_id; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.cluster_server_uptime
    ADD CONSTRAINT fk_cluster_server_id FOREIGN KEY (server_id) REFERENCES public.cluster_server(server_id);


--
-- Name: cms_roles_ir fk_cms_roles_ir_ep; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.cms_roles_ir
    ADD CONSTRAINT fk_cms_roles_ir_ep FOREIGN KEY (endpoint_id) REFERENCES public.publishing_end_point(id);


--
-- Name: contentlet_version_info fk_con_ver_lockedby; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.contentlet_version_info
    ADD CONSTRAINT fk_con_ver_lockedby FOREIGN KEY (locked_by) REFERENCES public.user_(userid);


--
-- Name: template_containers fk_container_id; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.template_containers
    ADD CONSTRAINT fk_container_id FOREIGN KEY (container_id) REFERENCES public.identifier(id);


--
-- Name: container_version_info fk_container_version_info_identifier; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.container_version_info
    ADD CONSTRAINT fk_container_version_info_identifier FOREIGN KEY (identifier) REFERENCES public.identifier(id);


--
-- Name: container_version_info fk_container_version_info_live; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.container_version_info
    ADD CONSTRAINT fk_container_version_info_live FOREIGN KEY (live_inode) REFERENCES public.dot_containers(inode);


--
-- Name: container_version_info fk_container_version_info_working; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.container_version_info
    ADD CONSTRAINT fk_container_version_info_working FOREIGN KEY (working_inode) REFERENCES public.dot_containers(inode);


--
-- Name: contentlet fk_contentlet_lang; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.contentlet
    ADD CONSTRAINT fk_contentlet_lang FOREIGN KEY (language_id) REFERENCES public.language(id);


--
-- Name: contentlet_version_info fk_contentlet_version_info_identifier; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.contentlet_version_info
    ADD CONSTRAINT fk_contentlet_version_info_identifier FOREIGN KEY (identifier) REFERENCES public.identifier(id) ON DELETE CASCADE;


--
-- Name: contentlet_version_info fk_contentlet_version_info_lang; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.contentlet_version_info
    ADD CONSTRAINT fk_contentlet_version_info_lang FOREIGN KEY (lang) REFERENCES public.language(id);


--
-- Name: contentlet_version_info fk_contentlet_version_info_live; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.contentlet_version_info
    ADD CONSTRAINT fk_contentlet_version_info_live FOREIGN KEY (live_inode) REFERENCES public.contentlet(inode);


--
-- Name: contentlet_version_info fk_contentlet_version_info_working; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.contentlet_version_info
    ADD CONSTRAINT fk_contentlet_version_info_working FOREIGN KEY (working_inode) REFERENCES public.contentlet(inode);


--
-- Name: container_structures fk_cs_container_id; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.container_structures
    ADD CONSTRAINT fk_cs_container_id FOREIGN KEY (container_id) REFERENCES public.identifier(id);


--
-- Name: container_structures fk_cs_inode; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.container_structures
    ADD CONSTRAINT fk_cs_inode FOREIGN KEY (container_inode) REFERENCES public.inode(inode);


--
-- Name: publishing_bundle_environment fk_environment_id; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.publishing_bundle_environment
    ADD CONSTRAINT fk_environment_id FOREIGN KEY (environment_id) REFERENCES public.publishing_environment(id);


--
-- Name: workflow_step fk_escalation_action; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.workflow_step
    ADD CONSTRAINT fk_escalation_action FOREIGN KEY (escalation_action) REFERENCES public.workflow_action(id);


--
-- Name: fileassets_ir fk_file_ir_ep; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.fileassets_ir
    ADD CONSTRAINT fk_file_ir_ep FOREIGN KEY (endpoint_id) REFERENCES public.publishing_end_point(id);


--
-- Name: folder fk_folder_file_structure_type; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.folder
    ADD CONSTRAINT fk_folder_file_structure_type FOREIGN KEY (default_file_type) REFERENCES public.structure(inode);


--
-- Name: folders_ir fk_folder_ir_ep; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.folders_ir
    ADD CONSTRAINT fk_folder_ir_ep FOREIGN KEY (endpoint_id) REFERENCES public.publishing_end_point(id);


--
-- Name: link_version_info fk_link_ver_info_lockedby; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.link_version_info
    ADD CONSTRAINT fk_link_ver_info_lockedby FOREIGN KEY (locked_by) REFERENCES public.user_(userid);


--
-- Name: link_version_info fk_link_version_info_identifier; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.link_version_info
    ADD CONSTRAINT fk_link_version_info_identifier FOREIGN KEY (identifier) REFERENCES public.identifier(id);


--
-- Name: link_version_info fk_link_version_info_live; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.link_version_info
    ADD CONSTRAINT fk_link_version_info_live FOREIGN KEY (live_inode) REFERENCES public.links(inode);


--
-- Name: link_version_info fk_link_version_info_working; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.link_version_info
    ADD CONSTRAINT fk_link_version_info_working FOREIGN KEY (working_inode) REFERENCES public.links(inode);


--
-- Name: htmlpages_ir fk_page_ir_ep; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.htmlpages_ir
    ADD CONSTRAINT fk_page_ir_ep FOREIGN KEY (endpoint_id) REFERENCES public.publishing_end_point(id);


--
-- Name: chain_state_parameter fk_parameter_state; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.chain_state_parameter
    ADD CONSTRAINT fk_parameter_state FOREIGN KEY (chain_state_id) REFERENCES public.chain_state(id);


--
-- Name: plugin_property fk_plugin_plugin_property; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.plugin_property
    ADD CONSTRAINT fk_plugin_plugin_property FOREIGN KEY (plugin_id) REFERENCES public.plugin(id);


--
-- Name: publishing_bundle fk_publishing_bundle_owner; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.publishing_bundle
    ADD CONSTRAINT fk_publishing_bundle_owner FOREIGN KEY (owner) REFERENCES public.user_(userid);


--
-- Name: schemes_ir fk_scheme_ir_ep; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.schemes_ir
    ADD CONSTRAINT fk_scheme_ir_ep FOREIGN KEY (endpoint_id) REFERENCES public.publishing_end_point(id);


--
-- Name: chain_state fk_state_chain; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.chain_state
    ADD CONSTRAINT fk_state_chain FOREIGN KEY (chain_id) REFERENCES public.chain(id);


--
-- Name: chain_state fk_state_code; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.chain_state
    ADD CONSTRAINT fk_state_code FOREIGN KEY (link_code_id) REFERENCES public.chain_link_code(id);


--
-- Name: structure fk_structure_folder; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.structure
    ADD CONSTRAINT fk_structure_folder FOREIGN KEY (folder) REFERENCES public.folder(inode);


--
-- Name: structure fk_structure_host; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.structure
    ADD CONSTRAINT fk_structure_host FOREIGN KEY (host) REFERENCES public.identifier(id);


--
-- Name: contentlet fk_structure_inode; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.contentlet
    ADD CONSTRAINT fk_structure_inode FOREIGN KEY (structure_inode) REFERENCES public.structure(inode);


--
-- Name: structures_ir fk_structure_ir_ep; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.structures_ir
    ADD CONSTRAINT fk_structure_ir_ep FOREIGN KEY (endpoint_id) REFERENCES public.publishing_end_point(id);


--
-- Name: tag_inode fk_tag_inode_tagid; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.tag_inode
    ADD CONSTRAINT fk_tag_inode_tagid FOREIGN KEY (tag_id) REFERENCES public.tag(tag_id);


--
-- Name: container_version_info fk_tainer_ver_info_lockedby; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.container_version_info
    ADD CONSTRAINT fk_tainer_ver_info_lockedby FOREIGN KEY (locked_by) REFERENCES public.user_(userid);


--
-- Name: template_version_info fk_temp_ver_info_lockedby; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.template_version_info
    ADD CONSTRAINT fk_temp_ver_info_lockedby FOREIGN KEY (locked_by) REFERENCES public.user_(userid);


--
-- Name: template_containers fk_template_id; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.template_containers
    ADD CONSTRAINT fk_template_id FOREIGN KEY (template_id) REFERENCES public.identifier(id);


--
-- Name: template_version_info fk_template_version_info_identifier; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.template_version_info
    ADD CONSTRAINT fk_template_version_info_identifier FOREIGN KEY (identifier) REFERENCES public.identifier(id);


--
-- Name: template_version_info fk_template_version_info_live; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.template_version_info
    ADD CONSTRAINT fk_template_version_info_live FOREIGN KEY (live_inode) REFERENCES public.template(inode);


--
-- Name: template_version_info fk_template_version_info_working; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.template_version_info
    ADD CONSTRAINT fk_template_version_info_working FOREIGN KEY (working_inode) REFERENCES public.template(inode);


--
-- Name: dot_containers fk_user_containers; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.dot_containers
    ADD CONSTRAINT fk_user_containers FOREIGN KEY (mod_user) REFERENCES public.user_(userid);


--
-- Name: contentlet fk_user_contentlet; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.contentlet
    ADD CONSTRAINT fk_user_contentlet FOREIGN KEY (mod_user) REFERENCES public.user_(userid);


--
-- Name: links fk_user_links; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.links
    ADD CONSTRAINT fk_user_links FOREIGN KEY (mod_user) REFERENCES public.user_(userid);


--
-- Name: template fk_user_template; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.template
    ADD CONSTRAINT fk_user_template FOREIGN KEY (mod_user) REFERENCES public.user_(userid);


--
-- Name: workflow_action_step fk_w_action_step_action_id; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.workflow_action_step
    ADD CONSTRAINT fk_w_action_step_action_id FOREIGN KEY (action_id) REFERENCES public.workflow_action(id);


--
-- Name: workflow_action_step fk_w_action_step_step_id; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.workflow_action_step
    ADD CONSTRAINT fk_w_action_step_step_id FOREIGN KEY (step_id) REFERENCES public.workflow_step(id);


--
-- Name: workflow_task fk_workflow_assign; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.workflow_task
    ADD CONSTRAINT fk_workflow_assign FOREIGN KEY (assigned_to) REFERENCES public.cms_role(id);


--
-- Name: workflowtask_files fk_workflow_id; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.workflowtask_files
    ADD CONSTRAINT fk_workflow_id FOREIGN KEY (workflowtask_id) REFERENCES public.workflow_task(id);


--
-- Name: workflow_task fk_workflow_step; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.workflow_task
    ADD CONSTRAINT fk_workflow_step FOREIGN KEY (status) REFERENCES public.workflow_step(id);


--
-- Name: workflow_task fk_workflow_task_language; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.workflow_task
    ADD CONSTRAINT fk_workflow_task_language FOREIGN KEY (language_id) REFERENCES public.language(id);


--
-- Name: analytic_summary_pages fka1ad33b9ed30e054; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.analytic_summary_pages
    ADD CONSTRAINT fka1ad33b9ed30e054 FOREIGN KEY (summary_id) REFERENCES public.analytic_summary(id);


--
-- Name: template fkb13acc7a5fb51eb; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.template
    ADD CONSTRAINT fkb13acc7a5fb51eb FOREIGN KEY (inode) REFERENCES public.inode(inode);


--
-- Name: folder fkb45d1c6e5fb51eb; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.folder
    ADD CONSTRAINT fkb45d1c6e5fb51eb FOREIGN KEY (inode) REFERENCES public.inode(inode);


--
-- Name: communication fkc24acfd65fb51eb; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.communication
    ADD CONSTRAINT fkc24acfd65fb51eb FOREIGN KEY (inode) REFERENCES public.inode(inode);


--
-- Name: cms_layouts_portlets fkcms_layouts_portlets; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.cms_layouts_portlets
    ADD CONSTRAINT fkcms_layouts_portlets FOREIGN KEY (layout_id) REFERENCES public.cms_layout(id);


--
-- Name: cms_role fkcms_role_parent; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.cms_role
    ADD CONSTRAINT fkcms_role_parent FOREIGN KEY (parent) REFERENCES public.cms_role(id);


--
-- Name: user_comments fkdf1b37e85fb51eb; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.user_comments
    ADD CONSTRAINT fkdf1b37e85fb51eb FOREIGN KEY (inode) REFERENCES public.inode(inode);


--
-- Name: user_filter fke042126c5fb51eb; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.user_filter
    ADD CONSTRAINT fke042126c5fb51eb FOREIGN KEY (inode) REFERENCES public.inode(inode);


--
-- Name: relationship fkf06476385fb51eb; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.relationship
    ADD CONSTRAINT fkf06476385fb51eb FOREIGN KEY (inode) REFERENCES public.inode(inode);


--
-- Name: campaign fkf7a901105fb51eb; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.campaign
    ADD CONSTRAINT fkf7a901105fb51eb FOREIGN KEY (inode) REFERENCES public.inode(inode);


--
-- Name: contentlet fkfc4ef025fb51eb; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.contentlet
    ADD CONSTRAINT fkfc4ef025fb51eb FOREIGN KEY (inode) REFERENCES public.inode(inode);


--
-- Name: layouts_cms_roles fklayouts_cms_roles1; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.layouts_cms_roles
    ADD CONSTRAINT fklayouts_cms_roles1 FOREIGN KEY (role_id) REFERENCES public.cms_role(id);


--
-- Name: layouts_cms_roles fklayouts_cms_roles2; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.layouts_cms_roles
    ADD CONSTRAINT fklayouts_cms_roles2 FOREIGN KEY (layout_id) REFERENCES public.cms_layout(id);


--
-- Name: users_cms_roles fkusers_cms_roles1; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.users_cms_roles
    ADD CONSTRAINT fkusers_cms_roles1 FOREIGN KEY (role_id) REFERENCES public.cms_role(id);


--
-- Name: users_cms_roles fkusers_cms_roles2; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.users_cms_roles
    ADD CONSTRAINT fkusers_cms_roles2 FOREIGN KEY (user_id) REFERENCES public.user_(userid);


--
-- Name: folder folder_identifier_fk; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.folder
    ADD CONSTRAINT folder_identifier_fk FOREIGN KEY (identifier) REFERENCES public.identifier(id);


--
-- Name: links links_identifier_fk; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.links
    ADD CONSTRAINT links_identifier_fk FOREIGN KEY (identifier) REFERENCES public.identifier(id);


--
-- Name: permission permission_role_fk; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.permission
    ADD CONSTRAINT permission_role_fk FOREIGN KEY (roleid) REFERENCES public.cms_role(id);


--
-- Name: qrtz_blob_triggers qrtz_blob_triggers_trigger_name_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.qrtz_blob_triggers
    ADD CONSTRAINT qrtz_blob_triggers_trigger_name_fkey FOREIGN KEY (trigger_name, trigger_group) REFERENCES public.qrtz_triggers(trigger_name, trigger_group);


--
-- Name: qrtz_cron_triggers qrtz_cron_triggers_trigger_name_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.qrtz_cron_triggers
    ADD CONSTRAINT qrtz_cron_triggers_trigger_name_fkey FOREIGN KEY (trigger_name, trigger_group) REFERENCES public.qrtz_triggers(trigger_name, trigger_group);


--
-- Name: qrtz_excl_blob_triggers qrtz_excl_blob_triggers_trigger_name_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.qrtz_excl_blob_triggers
    ADD CONSTRAINT qrtz_excl_blob_triggers_trigger_name_fkey FOREIGN KEY (trigger_name, trigger_group) REFERENCES public.qrtz_excl_triggers(trigger_name, trigger_group);


--
-- Name: qrtz_excl_cron_triggers qrtz_excl_cron_triggers_trigger_name_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.qrtz_excl_cron_triggers
    ADD CONSTRAINT qrtz_excl_cron_triggers_trigger_name_fkey FOREIGN KEY (trigger_name, trigger_group) REFERENCES public.qrtz_excl_triggers(trigger_name, trigger_group);


--
-- Name: qrtz_excl_job_listeners qrtz_excl_job_listeners_job_name_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.qrtz_excl_job_listeners
    ADD CONSTRAINT qrtz_excl_job_listeners_job_name_fkey FOREIGN KEY (job_name, job_group) REFERENCES public.qrtz_excl_job_details(job_name, job_group);


--
-- Name: qrtz_excl_simple_triggers qrtz_excl_simple_triggers_trigger_name_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.qrtz_excl_simple_triggers
    ADD CONSTRAINT qrtz_excl_simple_triggers_trigger_name_fkey FOREIGN KEY (trigger_name, trigger_group) REFERENCES public.qrtz_excl_triggers(trigger_name, trigger_group);


--
-- Name: qrtz_excl_trigger_listeners qrtz_excl_trigger_listeners_trigger_name_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.qrtz_excl_trigger_listeners
    ADD CONSTRAINT qrtz_excl_trigger_listeners_trigger_name_fkey FOREIGN KEY (trigger_name, trigger_group) REFERENCES public.qrtz_excl_triggers(trigger_name, trigger_group);


--
-- Name: qrtz_excl_triggers qrtz_excl_triggers_job_name_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.qrtz_excl_triggers
    ADD CONSTRAINT qrtz_excl_triggers_job_name_fkey FOREIGN KEY (job_name, job_group) REFERENCES public.qrtz_excl_job_details(job_name, job_group);


--
-- Name: qrtz_job_listeners qrtz_job_listeners_job_name_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.qrtz_job_listeners
    ADD CONSTRAINT qrtz_job_listeners_job_name_fkey FOREIGN KEY (job_name, job_group) REFERENCES public.qrtz_job_details(job_name, job_group);


--
-- Name: qrtz_simple_triggers qrtz_simple_triggers_trigger_name_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.qrtz_simple_triggers
    ADD CONSTRAINT qrtz_simple_triggers_trigger_name_fkey FOREIGN KEY (trigger_name, trigger_group) REFERENCES public.qrtz_triggers(trigger_name, trigger_group);


--
-- Name: qrtz_trigger_listeners qrtz_trigger_listeners_trigger_name_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.qrtz_trigger_listeners
    ADD CONSTRAINT qrtz_trigger_listeners_trigger_name_fkey FOREIGN KEY (trigger_name, trigger_group) REFERENCES public.qrtz_triggers(trigger_name, trigger_group);


--
-- Name: qrtz_triggers qrtz_triggers_job_name_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.qrtz_triggers
    ADD CONSTRAINT qrtz_triggers_job_name_fkey FOREIGN KEY (job_name, job_group) REFERENCES public.qrtz_job_details(job_name, job_group);


--
-- Name: rule_action_pars rule_action_pars_rule_action_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.rule_action_pars
    ADD CONSTRAINT rule_action_pars_rule_action_id_fkey FOREIGN KEY (rule_action_id) REFERENCES public.rule_action(id);


--
-- Name: rule_action rule_action_rule_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.rule_action
    ADD CONSTRAINT rule_action_rule_id_fkey FOREIGN KEY (rule_id) REFERENCES public.dot_rule(id);


--
-- Name: rule_condition rule_condition_condition_group_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.rule_condition
    ADD CONSTRAINT rule_condition_condition_group_fkey FOREIGN KEY (condition_group) REFERENCES public.rule_condition_group(id);


--
-- Name: rule_condition_group rule_condition_group_rule_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.rule_condition_group
    ADD CONSTRAINT rule_condition_group_rule_id_fkey FOREIGN KEY (rule_id) REFERENCES public.dot_rule(id);


--
-- Name: rule_condition_value rule_condition_value_condition_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.rule_condition_value
    ADD CONSTRAINT rule_condition_value_condition_id_fkey FOREIGN KEY (condition_id) REFERENCES public.rule_condition(id);


--
-- Name: template template_identifier_fk; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.template
    ADD CONSTRAINT template_identifier_fk FOREIGN KEY (identifier) REFERENCES public.identifier(id);


--
-- Name: workflow_action_class workflow_action_class_action_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.workflow_action_class
    ADD CONSTRAINT workflow_action_class_action_id_fkey FOREIGN KEY (action_id) REFERENCES public.workflow_action(id);


--
-- Name: workflow_action_class_pars workflow_action_class_pars_workflow_action_class_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.workflow_action_class_pars
    ADD CONSTRAINT workflow_action_class_pars_workflow_action_class_id_fkey FOREIGN KEY (workflow_action_class_id) REFERENCES public.workflow_action_class(id);


--
-- Name: workflow_action workflow_action_next_assign_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.workflow_action
    ADD CONSTRAINT workflow_action_next_assign_fkey FOREIGN KEY (next_assign) REFERENCES public.cms_role(id);


--
-- Name: workflow_scheme_x_structure workflow_scheme_x_structure_scheme_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.workflow_scheme_x_structure
    ADD CONSTRAINT workflow_scheme_x_structure_scheme_id_fkey FOREIGN KEY (scheme_id) REFERENCES public.workflow_scheme(id);


--
-- Name: workflow_scheme_x_structure workflow_scheme_x_structure_structure_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.workflow_scheme_x_structure
    ADD CONSTRAINT workflow_scheme_x_structure_structure_id_fkey FOREIGN KEY (structure_id) REFERENCES public.structure(inode);


--
-- Name: workflow_step workflow_step_scheme_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.workflow_step
    ADD CONSTRAINT workflow_step_scheme_id_fkey FOREIGN KEY (scheme_id) REFERENCES public.workflow_scheme(id);


--
-- Name: workflow_comment workflowtask_id_comment_fk; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.workflow_comment
    ADD CONSTRAINT workflowtask_id_comment_fk FOREIGN KEY (workflowtask_id) REFERENCES public.workflow_task(id);


--
-- Name: workflow_history workflowtask_id_history_fk; Type: FK CONSTRAINT; Schema: public; Owner: dotcms_dev
--

ALTER TABLE ONLY public.workflow_history
    ADD CONSTRAINT workflowtask_id_history_fk FOREIGN KEY (workflowtask_id) REFERENCES public.workflow_task(id);


--
-- PostgreSQL database dump complete
--

