''' auth_middleware

    Simple Authentication module for MOC Reporting CSV Export Utility built from
    Flask primitives
'''

from flask import request, Response

def _validate():
  ''' _validate: () -> bool

      TODO: Implement based on:
       - User (sso?) authentication
       - role for requested project
  '''
  return True

def authorized(endpoint_call):
  ''' authorized : (f : * -> *) -> (f' : * -> *)

      authorized decorates a function/endpoint with middleware that validates
      the given prior. 
  '''
  def wrap(*args, **kwargs):
    if _validate():
      return endpoint_call(*args, **kwargs)
    return Response(code=401)
  return wrap
