package j_account

// This file was generated by the swagger tool.
// Editing this file might prove futile when you re-run the swagger generate command

import (
	"net/http"
	"time"

	"golang.org/x/net/context"

	"github.com/go-openapi/errors"
	"github.com/go-openapi/runtime"
	cr "github.com/go-openapi/runtime/client"

	strfmt "github.com/go-openapi/strfmt"

	"koding/remoteapi/models"
)

// NewPostRemoteAPIJAccountUnlinkOauthIDParams creates a new PostRemoteAPIJAccountUnlinkOauthIDParams object
// with the default values initialized.
func NewPostRemoteAPIJAccountUnlinkOauthIDParams() *PostRemoteAPIJAccountUnlinkOauthIDParams {
	var ()
	return &PostRemoteAPIJAccountUnlinkOauthIDParams{

		timeout: cr.DefaultTimeout,
	}
}

// NewPostRemoteAPIJAccountUnlinkOauthIDParamsWithTimeout creates a new PostRemoteAPIJAccountUnlinkOauthIDParams object
// with the default values initialized, and the ability to set a timeout on a request
func NewPostRemoteAPIJAccountUnlinkOauthIDParamsWithTimeout(timeout time.Duration) *PostRemoteAPIJAccountUnlinkOauthIDParams {
	var ()
	return &PostRemoteAPIJAccountUnlinkOauthIDParams{

		timeout: timeout,
	}
}

// NewPostRemoteAPIJAccountUnlinkOauthIDParamsWithContext creates a new PostRemoteAPIJAccountUnlinkOauthIDParams object
// with the default values initialized, and the ability to set a context for a request
func NewPostRemoteAPIJAccountUnlinkOauthIDParamsWithContext(ctx context.Context) *PostRemoteAPIJAccountUnlinkOauthIDParams {
	var ()
	return &PostRemoteAPIJAccountUnlinkOauthIDParams{

		Context: ctx,
	}
}

/*PostRemoteAPIJAccountUnlinkOauthIDParams contains all the parameters to send to the API endpoint
for the post remote API j account unlink oauth ID operation typically these are written to a http.Request
*/
type PostRemoteAPIJAccountUnlinkOauthIDParams struct {

	/*Body
	  body of the request

	*/
	Body models.DefaultSelector
	/*ID
	  Mongo ID of target instance

	*/
	ID string

	timeout    time.Duration
	Context    context.Context
	HTTPClient *http.Client
}

// WithTimeout adds the timeout to the post remote API j account unlink oauth ID params
func (o *PostRemoteAPIJAccountUnlinkOauthIDParams) WithTimeout(timeout time.Duration) *PostRemoteAPIJAccountUnlinkOauthIDParams {
	o.SetTimeout(timeout)
	return o
}

// SetTimeout adds the timeout to the post remote API j account unlink oauth ID params
func (o *PostRemoteAPIJAccountUnlinkOauthIDParams) SetTimeout(timeout time.Duration) {
	o.timeout = timeout
}

// WithContext adds the context to the post remote API j account unlink oauth ID params
func (o *PostRemoteAPIJAccountUnlinkOauthIDParams) WithContext(ctx context.Context) *PostRemoteAPIJAccountUnlinkOauthIDParams {
	o.SetContext(ctx)
	return o
}

// SetContext adds the context to the post remote API j account unlink oauth ID params
func (o *PostRemoteAPIJAccountUnlinkOauthIDParams) SetContext(ctx context.Context) {
	o.Context = ctx
}

// WithBody adds the body to the post remote API j account unlink oauth ID params
func (o *PostRemoteAPIJAccountUnlinkOauthIDParams) WithBody(body models.DefaultSelector) *PostRemoteAPIJAccountUnlinkOauthIDParams {
	o.SetBody(body)
	return o
}

// SetBody adds the body to the post remote API j account unlink oauth ID params
func (o *PostRemoteAPIJAccountUnlinkOauthIDParams) SetBody(body models.DefaultSelector) {
	o.Body = body
}

// WithID adds the id to the post remote API j account unlink oauth ID params
func (o *PostRemoteAPIJAccountUnlinkOauthIDParams) WithID(id string) *PostRemoteAPIJAccountUnlinkOauthIDParams {
	o.SetID(id)
	return o
}

// SetID adds the id to the post remote API j account unlink oauth ID params
func (o *PostRemoteAPIJAccountUnlinkOauthIDParams) SetID(id string) {
	o.ID = id
}

// WriteToRequest writes these params to a swagger request
func (o *PostRemoteAPIJAccountUnlinkOauthIDParams) WriteToRequest(r runtime.ClientRequest, reg strfmt.Registry) error {

	r.SetTimeout(o.timeout)
	var res []error

	if err := r.SetBodyParam(o.Body); err != nil {
		return err
	}

	// path param id
	if err := r.SetPathParam("id", o.ID); err != nil {
		return err
	}

	if len(res) > 0 {
		return errors.CompositeValidationError(res...)
	}
	return nil
}
