module.exports = (env) ->
  Promise = env.require 'bluebird'
  assert = env.require 'cassert'
  events = require 'events'
  _ = require 'lodash'

  class Error

    constructor: () ->

    errorHandler: (error) =>
      switch(error)
        when "Unauthorized"
          env.logger.error "ErrorHandler: Unauthorized - No or invalid access token"
        when "Forbidden"
          env.logger.error "ErrorHandler: Forbidden - Scope has not been granted"
        when "NotFound"
          env.logger.error "ErrorHandler: The requested resource was not found"
        when "NoProgramSelected"
          env.logger.error "ErrorHandler: No program is currently selected"
        when "NoProgramActive"
          env.logger.error "ErrorHandler: No program is currently active"
        when "NotAcceptable"
          env.logger.error "ErrorHandler: The resource identified by the request is only capable of generating response entities which have content characteristics not acceptable according to the accept headers sent in the request."
        when "RequestTimeout"
          env.logger.error "ErrorHandler: API Server failed to produce an answer or has no connection to backend service"
        when "HomeApplianceError"
          env.logger.error "ErrorHandler: An error occured during communication with the home appliance or the home appliance itself answered with an error, e.g. because the issued command was unacceptable in the current state."
        when "SelectedProgramNotSet"
          env.logger.error "ErrorHandler: No program is currently selected"
        when "ActiveProgramNotSet"
          env.logger.error "ErrorHandler: No program is currently active"
        when "WrongOperationState"
          env.logger.error "ErrorHandler: Request cannot be performed since the OperationState is wrong"
        when "ProgramNotAvailable"
          env.logger.error "ErrorHandler: The requested program is not available"
        when "ContentTypeError"
          env.logger.error "ErrorHandler: The request's Content-Type is not supported."
        when "QuotaError"
          env.logger.error "ErrorHandler: The number of requests for a specific endpoint exceeded the quota of the client."
        when "InternalError"
          env.logger.error "ErrorHandler: Internal Server Error"
        when "Conflict"
          env.logger.error "ErrorHandler: Command/Query cannot be executed for the home appliance, " + JSON.stringify(error,null,2)
        when "200"
          env.logger.error "ErrorHandler: active program"
        when "401"
          env.logger.error "ErrorHandler: Unauthorized"
        when "403"
          env.logger.error "ErrorHandler: Forbidden"
        when "404"
          env.logger.error "ErrorHandler: NoProgramActive"
        when "406"
          env.logger.error "ErrorHandler: NotAcceptable"
        when "409"
          env.logger.error "ErrorHandler: HomeApplianceError"
        when "429"
          env.logger.error "ErrorHandler: QuotaError"
        when "500"
          env.logger.error "ErrorHandler: InternalError"
        else
          env.logger.error "ErrorHandler: Unknown error #{error}"

