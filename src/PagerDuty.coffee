request = require 'request'


_object = (kvpairs) ->
  res = {}
  for kv in kvpairs
    res[kv[0]] = kv[1]
  res

_stripUndefined = (obj) ->
  _object([k, v] for k, v of obj when v isnt undefined)

_expect = (expectedStatusCode, callback) ->
  (err, response, body) ->
    try
      body = JSON.parse body

    if err or response.statusCode != expectedStatusCode
      callback err || if body && body.error then new Error(body.error.errors[0]) else new Error('Unexpected HTTP code: ' + response.statusCode)
    else
      callback null, body


class PagerDuty
  module.exports = PagerDuty

  constructor: ({@serviceKey, @subdomain}) ->
    throw new Error 'PagerDuty.constructor: Need serviceKey!' unless @serviceKey?

  create: ({description, incidentKey, details, callback}) ->
    throw new Error 'PagerDuty.create: Need description!' unless description?

    @_eventRequest arguments[0] extends eventType: 'trigger'

  acknowledge: ({incidentKey, details, description, callback}) ->
    throw new Error 'PagerDuty.acknowledge: Need incidentKey!' unless incidentKey?

    @_eventRequest arguments[0] extends eventType: 'acknowledge'

  resolve: ({incidentKey, details, description, callback}) ->
    throw new Error 'PagerDuty.resolve: Need incidentKey!' unless incidentKey?

    @_eventRequest arguments[0] extends eventType: 'resolve'

  _eventRequest: ({description, incidentKey, eventType, details, callback}) ->
    throw new Error 'PagerDuty._request: Need eventType!' unless eventType?

    details     ||= {}
    callback    ||= ->

    json =
      service_key: @serviceKey
      event_type: eventType
      description: description
      details: details
      incident_key: incidentKey

    request
      method: 'POST'
      uri: 'https://events.pagerduty.com/generic/2010-04-15/create_event.json'
      json: _stripUndefined json
    , (err, response, body) ->
      if err or response.statusCode != 200
        callback err || new Error(body.errors[0])
      else
        callback null, body

  getEscalationPolicies: ({query, offset, limit, callback}) ->
    @_getRequest
      resource: 'escalation_policies'
      callback: callback
      qs:
        query: query
        offset: offset
        limit: limit

  getEscalationPoliciesOnCall: ({query, offset, limit, callback}) ->
    @_getRequest
      resource: 'escalation_policies/oncall'
      callback: callback
      qs:
        query: query
        offset: offset
        limit: limit

  createEscalationPolicy: ({name, escalationRules, callback}) ->
    @_postRequest
      resource: 'escalation_policies'
      callback: callback
      json:
        name: name
        escalation_rules: escalationRules

  getUsers: ({query, offset, limit, callback}) ->
    @_getRequest
      resource: 'users'
      callback: callback
      qs:
        query: query
        offset: offset
        limit: limit

  createUser: ({name, email, requesterId, callback}) ->
    @_postRequest
      resource: 'users'
      callback: callback
      json:
        name: name
        email: email
        requester_id: requesterId

  getServices: ({query, offset, limit, callback}) ->
    @_getRequest
      resource: 'services'
      callback: callback
      qs:
        query: query
        offset: offset
        limit: limit

  createService: ({name, escalationPolicyId, type, serviceKey, callback}) ->
    @_postRequest
      resource: 'services'
      callback: callback
      json:
        service:
          name: name
          escalation_policy_id: escalationPolicyId
          type: type
          service_key: serviceKey

  _getRequest: ({resource, qs, offset, limit, callback}) ->
    callback    ||= ->
    uri = 'https://' + @subdomain + '.pagerduty.com/api/v1/' + resource

    request
      method: 'GET'
      uri: uri
      qs: _stripUndefined qs
      headers: { 'Authorization': 'Token token=' + @serviceKey }
    , _expect(200, callback)

  _postRequest: ({resource, json, callback}) ->
    callback    ||= ->
    uri = 'https://' + @subdomain + '.pagerduty.com/api/v1/' + resource

    request
      method: 'POST'
      uri: uri
      json: _stripUndefined json
      headers: { 'Authorization': 'Token token=' + @serviceKey }
    , _expect(201, callback)
