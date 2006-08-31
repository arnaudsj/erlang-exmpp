% $Id$

% --------------------------------------------------------------------
% Records to represent XML nodes.
% --------------------------------------------------------------------

% Elements without namespace support.
-record(xmlelement, {
	name,			% Tag name
	attrs = [],		% Attribute list
	children = undefined	% Children (tags or CDATA)
}).

-record(xmlendelement, {
	name
}).

% Elements WITH namespace support.
-record(xmlnselement, {
	ns = undefined,		% Tag namespace
	prefix = undefined,	% Namespace prefix
	name,			% Tag name
	attrs = [],		% Attribute list
	children = undefined	% Children (tags or CDATA)
}).

-record(xmlnsendelement, {
	ns = undefined,
	prefix = undefined,
	name
}).

% Attributes WITH namespace support.
-record(xmlattr, {
	ns = undefined,
	prefix = undefined,
	name,
	value
}).

% Character data.
-record(xmlcdata, {
	cdata = []	% Character data
}).

% Processing Instruction.
-record(xmlpi, {
	target,
	value
}).

% --------------------------------------------------------------------
% Records to represent events.
% --------------------------------------------------------------------

% Stream start.
-record(xmlstreamstart, {
	element		% #xmlnselement
}).

% Depth 1 element, inside a stream.
-record(xmlstreamelement, {
	element		% #xmlnselement
}).

% Stream end.
-record(xmlstreamend, {
	endelement	% xmlnsendelement
}).

% --------------------------------------------------------------------
% Records to represent XMPP/Jabber specific structures.
% --------------------------------------------------------------------

-record(jid, {
	user,
	server,
	resource,
	luser,
	lserver,
	lresource
}).

-record(iq, {
	id = "",
	type,
	xmlns = "",
	lang = "",
	sub_el
}).

% --------------------------------------------------------------------
% Defines for exmpp_jlib.
% --------------------------------------------------------------------

-define(NS_XML,           'http://www.w3.org/XML/1998/namespace').
-define(NS_XMPP,          'http://etherx.jabber.org/streams').
-define(NS_JABBER_CLIENT, 'jabber:client').
-define(NS_JABBER_SERVER, 'jabber:server').
-define(NS_JABBER_AUTH,   'jabber:iq:auth').
-define(NS_XMPP_STREAMS,  'urn:ietf:params:xml:ns:xmpp-streams').
-define(NS_XMPP_STANZAS,  'urn:ietf:params:xml:ns:xmpp-stanzas').
-define(NS_TLS,           'urn:ietf:params:xml:ns:xmpp-tls').
-define(NS_SASL,          'urn:ietf:params:xml:ns:xmpp-sasl').
-define(NS_COMPRESS,      'http://jabber.org/features/compress').

-define(NS_DELAY, "jabber:x:delay").

% vim:ft=erlang:
