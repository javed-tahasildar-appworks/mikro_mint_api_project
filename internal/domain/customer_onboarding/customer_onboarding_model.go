package customer_onboarding

import "time"

type CustomerOnboardingModel struct {
	ID             int64
	CustomerCode   string
	FirstName      string
	LastName       string
	DateOfBirth    *time.Time
	Gender         *string
	Email          *string
	PhoneNumber    *string
	AadhaarNumber  *string
	PANNumber      *string
	Address        *string
	City           *string
	State          *string
	Pincode        *string
	KYCStatus      string
	CustomerStatus string
	CreatedAt      time.Time
	UpdatedAt      *time.Time
	DeletedAt      *time.Time
}
