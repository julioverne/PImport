/*
 Copyright (c) 2012-2015, Pierre-Olivier Latour
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 * The name of Pierre-Olivier Latour may not be used to endorse
 or promote products derived from this software without specific
 prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL PIERRE-OLIVIER LATOUR BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

// http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html
// http://www.iana.org/assignments/http-status-codes/http-status-codes.xhtml

#import <Foundation/Foundation.h>

/**
 *  Convenience constants for "informational" HTTP status codes.
 */
typedef NS_ENUM(NSInteger, PImportWebServerInformationalHTTPStatusCode) {
  kPImportWebServerHTTPStatusCode_Continue = 100,
  kPImportWebServerHTTPStatusCode_SwitchingProtocols = 101,
  kPImportWebServerHTTPStatusCode_Processing = 102
};

/**
 *  Convenience constants for "successful" HTTP status codes.
 */
typedef NS_ENUM(NSInteger, PImportWebServerSuccessfulHTTPStatusCode) {
  kPImportWebServerHTTPStatusCode_OK = 200,
  kPImportWebServerHTTPStatusCode_Created = 201,
  kPImportWebServerHTTPStatusCode_Accepted = 202,
  kPImportWebServerHTTPStatusCode_NonAuthoritativeInformation = 203,
  kPImportWebServerHTTPStatusCode_NoContent = 204,
  kPImportWebServerHTTPStatusCode_ResetContent = 205,
  kPImportWebServerHTTPStatusCode_PartialContent = 206,
  kPImportWebServerHTTPStatusCode_MultiStatus = 207,
  kPImportWebServerHTTPStatusCode_AlreadyReported = 208
};

/**
 *  Convenience constants for "redirection" HTTP status codes.
 */
typedef NS_ENUM(NSInteger, PImportWebServerRedirectionHTTPStatusCode) {
  kPImportWebServerHTTPStatusCode_MultipleChoices = 300,
  kPImportWebServerHTTPStatusCode_MovedPermanently = 301,
  kPImportWebServerHTTPStatusCode_Found = 302,
  kPImportWebServerHTTPStatusCode_SeeOther = 303,
  kPImportWebServerHTTPStatusCode_NotModified = 304,
  kPImportWebServerHTTPStatusCode_UseProxy = 305,
  kPImportWebServerHTTPStatusCode_TemporaryRedirect = 307,
  kPImportWebServerHTTPStatusCode_PermanentRedirect = 308
};

/**
 *  Convenience constants for "client error" HTTP status codes.
 */
typedef NS_ENUM(NSInteger, PImportWebServerClientErrorHTTPStatusCode) {
  kPImportWebServerHTTPStatusCode_BadRequest = 400,
  kPImportWebServerHTTPStatusCode_Unauthorized = 401,
  kPImportWebServerHTTPStatusCode_PaymentRequired = 402,
  kPImportWebServerHTTPStatusCode_Forbidden = 403,
  kPImportWebServerHTTPStatusCode_NotFound = 404,
  kPImportWebServerHTTPStatusCode_MethodNotAllowed = 405,
  kPImportWebServerHTTPStatusCode_NotAcceptable = 406,
  kPImportWebServerHTTPStatusCode_ProxyAuthenticationRequired = 407,
  kPImportWebServerHTTPStatusCode_RequestTimeout = 408,
  kPImportWebServerHTTPStatusCode_Conflict = 409,
  kPImportWebServerHTTPStatusCode_Gone = 410,
  kPImportWebServerHTTPStatusCode_LengthRequired = 411,
  kPImportWebServerHTTPStatusCode_PreconditionFailed = 412,
  kPImportWebServerHTTPStatusCode_RequestEntityTooLarge = 413,
  kPImportWebServerHTTPStatusCode_RequestURITooLong = 414,
  kPImportWebServerHTTPStatusCode_UnsupportedMediaType = 415,
  kPImportWebServerHTTPStatusCode_RequestedRangeNotSatisfiable = 416,
  kPImportWebServerHTTPStatusCode_ExpectationFailed = 417,
  kPImportWebServerHTTPStatusCode_UnprocessableEntity = 422,
  kPImportWebServerHTTPStatusCode_Locked = 423,
  kPImportWebServerHTTPStatusCode_FailedDependency = 424,
  kPImportWebServerHTTPStatusCode_UpgradeRequired = 426,
  kPImportWebServerHTTPStatusCode_PreconditionRequired = 428,
  kPImportWebServerHTTPStatusCode_TooManyRequests = 429,
  kPImportWebServerHTTPStatusCode_RequestHeaderFieldsTooLarge = 431
};

/**
 *  Convenience constants for "server error" HTTP status codes.
 */
typedef NS_ENUM(NSInteger, PImportWebServerServerErrorHTTPStatusCode) {
  kPImportWebServerHTTPStatusCode_InternalServerError = 500,
  kPImportWebServerHTTPStatusCode_NotImplemented = 501,
  kPImportWebServerHTTPStatusCode_BadGateway = 502,
  kPImportWebServerHTTPStatusCode_ServiceUnavailable = 503,
  kPImportWebServerHTTPStatusCode_GatewayTimeout = 504,
  kPImportWebServerHTTPStatusCode_HTTPVersionNotSupported = 505,
  kPImportWebServerHTTPStatusCode_InsufficientStorage = 507,
  kPImportWebServerHTTPStatusCode_LoopDetected = 508,
  kPImportWebServerHTTPStatusCode_NotExtended = 510,
  kPImportWebServerHTTPStatusCode_NetworkAuthenticationRequired = 511
};
