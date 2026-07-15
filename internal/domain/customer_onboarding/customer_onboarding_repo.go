package customer_onboarding

import "context"

type Repository interface {
	Create(ctx context.Context, c *CustomerOnboardingModel) (*CustomerOnboardingModel, error)
	GetByID(ctx context.Context, id int64) (*CustomerOnboardingModel, error)
	GetByAadhaar(ctx context.Context, aadhaar string) (*CustomerOnboardingModel, error)
	UpdateStatus(ctx context.Context, id int64, status string) error
	UpdateKYCStatus(ctx context.Context, id int64, kyc string) error
	ListActive(ctx context.Context, limit, offset int32) ([]*CustomerOnboardingModel, error)
	SearchByName(ctx context.Context, q string, limit, offset int32) ([]*CustomerOnboardingModel, error)
	Delete(ctx context.Context, id int64) error
}
