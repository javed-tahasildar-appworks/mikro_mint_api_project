package customeronboardingusecase

import (
	"context"
	"errors"

	"microfinpro/internal/domain/customer_onboarding"
)

type Service struct {
	repo customer_onboarding.Repository
}

func NewService(r customer_onboarding.Repository) *Service {
	return &Service{repo: r}
}

func (s *Service) CreateCustomer(ctx context.Context, c *customer_onboarding.CustomerOnboardingModel) (*customer_onboarding.CustomerOnboardingModel, error) {
	// validation example
	if c.FirstName == "" || c.LastName == "" {
		return nil, errors.New("first and last name required")
	}
	// default values
	if c.KYCStatus == "" {
		c.KYCStatus = "pending"
	}
	if c.CustomerStatus == "" {
		c.CustomerStatus = "active"
	}
	return s.repo.Create(ctx, c)
}

func (s *Service) GetCustomerByID(ctx context.Context, id int64) (*customer_onboarding.CustomerOnboardingModel, error) {
	return s.repo.GetByID(ctx, id)
}

func (s *Service) UpdateStatus(ctx context.Context, id int64, status string) error {
	return s.repo.UpdateStatus(ctx, id, status)
}
