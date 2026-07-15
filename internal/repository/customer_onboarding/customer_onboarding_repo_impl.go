package customer_onboarding_repo_impl

import (
	"context"
	"database/sql"
	"errors"
	"time"

	queries "microfinpro/internal/db/queries/customer_onboarding"
	"microfinpro/internal/domain/customer_onboarding"
)

type customerRepo struct {
	q *queries.Queries
}

func NewCustomerRepo(db *sql.DB) customer_onboarding.Repository {
	return &customerRepo{
		q: queries.New(db),
	}
}

// Helper functions for pointer conversions
func stringPtr(ns sql.NullString) *string {
	if ns.Valid {
		return &ns.String
	}
	return nil
}

func timePtr(nt sql.NullTime) *time.Time {
	if nt.Valid {
		return &nt.Time
	}
	return nil
}

func nullString(s *string) sql.NullString {
	if s == nil {
		return sql.NullString{Valid: false}
	}
	return sql.NullString{String: *s, Valid: true}
}

func nullTime(t *time.Time) sql.NullTime {
	if t == nil {
		return sql.NullTime{Valid: false}
	}
	return sql.NullTime{Time: *t, Valid: true}
}

// Conversion functions between sqlc models and domain models
func toDomainCustomer(row queries.Customer) *customer_onboarding.CustomerOnboardingModel {
	return &customer_onboarding.CustomerOnboardingModel{
		ID:             int64(row.ID),
		CustomerCode:   row.CustomerCode.String,
		FirstName:      row.FirstName,
		LastName:       row.LastName,
		DateOfBirth:    timePtr(row.DateOfBirth),
		Gender:         stringPtr(row.Gender),
		Email:          stringPtr(row.Email),
		PhoneNumber:    stringPtr(row.PhoneNumber),
		AadhaarNumber:  stringPtr(row.AadhaarNumber),
		PANNumber:      stringPtr(row.PanNumber),
		Address:        stringPtr(row.Address),
		City:           stringPtr(row.City),
		State:          stringPtr(row.State),
		Pincode:        stringPtr(row.Pincode),
		KYCStatus:      row.KycStatus.String,
		CustomerStatus: row.CustomerStatus.String,
		CreatedAt:      *timePtr(row.CreatedAt),
		UpdatedAt:      timePtr(row.UpdatedAt),
		DeletedAt:      timePtr(row.DeletedAt),
	}
}

func toDomainFromCreateRow(row queries.CreateCustomerRow) *customer_onboarding.CustomerOnboardingModel {
	return &customer_onboarding.CustomerOnboardingModel{
		ID:             int64(row.ID),
		CustomerCode:   row.CustomerCode.String,
		FirstName:      row.FirstName,
		LastName:       row.LastName,
		DateOfBirth:    timePtr(row.DateOfBirth),
		Gender:         stringPtr(row.Gender),
		Email:          stringPtr(row.Email),
		PhoneNumber:    stringPtr(row.PhoneNumber),
		KYCStatus:      row.KycStatus.String,
		CustomerStatus: row.CustomerStatus.String,
		CreatedAt:      *timePtr(row.CreatedAt),
	}
}

func toDomainFromGetByIDRow(row queries.GetCustomerByIDRow) *customer_onboarding.CustomerOnboardingModel {
	return &customer_onboarding.CustomerOnboardingModel{
		ID:             int64(row.ID),
		CustomerCode:   row.CustomerCode.String,
		FirstName:      row.FirstName,
		LastName:       row.LastName,
		DateOfBirth:    timePtr(row.DateOfBirth),
		Gender:         stringPtr(row.Gender),
		Email:          stringPtr(row.Email),
		PhoneNumber:    stringPtr(row.PhoneNumber),
		Address:        stringPtr(row.Address),
		City:           stringPtr(row.City),
		State:          stringPtr(row.State),
		Pincode:        stringPtr(row.Pincode),
		KYCStatus:      row.KycStatus.String,
		CustomerStatus: row.CustomerStatus.String,
		CreatedAt:      *timePtr(row.CreatedAt),
		UpdatedAt:      timePtr(row.UpdatedAt),
	}
}

func toDomainFromGetByAadhaarRow(row queries.GetCustomerByAadhaarRow) *customer_onboarding.CustomerOnboardingModel {
	return &customer_onboarding.CustomerOnboardingModel{
		ID:             int64(row.ID),
		CustomerCode:   row.CustomerCode.String,
		FirstName:      row.FirstName,
		LastName:       row.LastName,
		Email:          stringPtr(row.Email),
		PhoneNumber:    stringPtr(row.PhoneNumber),
		AadhaarNumber:  stringPtr(row.AadhaarNumber),
		KYCStatus:      row.KycStatus.String,
		CustomerStatus: row.CustomerStatus.String,
	}
}

func toDomainFromListActiveRow(row queries.ListActiveCustomersRow) *customer_onboarding.CustomerOnboardingModel {
	return &customer_onboarding.CustomerOnboardingModel{
		ID:             int64(row.ID),
		CustomerCode:   row.CustomerCode.String,
		FirstName:      row.FirstName,
		LastName:       row.LastName,
		PhoneNumber:    stringPtr(row.PhoneNumber),
		Email:          stringPtr(row.Email),
		KYCStatus:      row.KycStatus.String,
		CustomerStatus: row.CustomerStatus.String,
		CreatedAt:      *timePtr(row.CreatedAt),
	}
}

func toDomainFromSearchRow(row queries.SearchCustomersByNameRow) *customer_onboarding.CustomerOnboardingModel {
	return &customer_onboarding.CustomerOnboardingModel{
		ID:             int64(row.ID),
		CustomerCode:   row.CustomerCode.String,
		FirstName:      row.FirstName,
		LastName:       row.LastName,
		Email:          stringPtr(row.Email),
		PhoneNumber:    stringPtr(row.PhoneNumber),
		KYCStatus:      row.KycStatus.String,
		CustomerStatus: row.CustomerStatus.String,
	}
}

// Repository implementation
func (r *customerRepo) Create(ctx context.Context, c *customer_onboarding.CustomerOnboardingModel) (*customer_onboarding.CustomerOnboardingModel, error) {
	arg := queries.CreateCustomerParams{
		FirstName:      c.FirstName,
		LastName:       c.LastName,
		DateOfBirth:    nullTime(c.DateOfBirth),
		Gender:         nullString(c.Gender),
		Email:          nullString(c.Email),
		PhoneNumber:    nullString(c.PhoneNumber),
		AadhaarNumber:  nullString(c.AadhaarNumber),
		PanNumber:      nullString(c.PANNumber),
		Address:        nullString(c.Address),
		City:           nullString(c.City),
		State:          nullString(c.State),
		Pincode:        nullString(c.Pincode),
		KycStatus:      sql.NullString{String: c.KYCStatus, Valid: c.KYCStatus != ""},
		CustomerStatus: sql.NullString{String: c.CustomerStatus, Valid: c.CustomerStatus != ""},
	}

	res, err := r.q.CreateCustomer(ctx, arg)
	if err != nil {
		return nil, err
	}

	return toDomainFromCreateRow(res), nil
}

func (r *customerRepo) GetByID(ctx context.Context, id int64) (*customer_onboarding.CustomerOnboardingModel, error) {
	res, err := r.q.GetCustomerByID(ctx, int32(id))
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, nil
		}
		return nil, err
	}

	return toDomainFromGetByIDRow(res), nil
}

func (r *customerRepo) GetByAadhaar(ctx context.Context, aadhaar string) (*customer_onboarding.CustomerOnboardingModel, error) {
	res, err := r.q.GetCustomerByAadhaar(ctx, sql.NullString{String: aadhaar, Valid: true})
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, nil
		}
		return nil, err
	}

	return toDomainFromGetByAadhaarRow(res), nil
}

func (r *customerRepo) UpdateStatus(ctx context.Context, id int64, status string) error {
	arg := queries.UpdateCustomerStatusParams{
		ID:             int32(id),
		CustomerStatus: sql.NullString{String: status, Valid: true},
	}
	return r.q.UpdateCustomerStatus(ctx, arg)
}

func (r *customerRepo) UpdateKYCStatus(ctx context.Context, id int64, kyc string) error {
	arg := queries.UpdateCustomerKYCStatusParams{
		ID:        int32(id),
		KycStatus: sql.NullString{String: kyc, Valid: true},
	}
	return r.q.UpdateCustomerKYCStatus(ctx, arg)
}

func (r *customerRepo) ListActive(ctx context.Context, limit, offset int32) ([]*customer_onboarding.CustomerOnboardingModel, error) {
	rows, err := r.q.ListActiveCustomers(ctx, queries.ListActiveCustomersParams{
		Limit:  limit,
		Offset: offset,
	})
	if err != nil {
		return nil, err
	}

	out := make([]*customer_onboarding.CustomerOnboardingModel, 0, len(rows))
	for _, row := range rows {
		out = append(out, toDomainFromListActiveRow(row))
	}

	return out, nil
}

func (r *customerRepo) SearchByName(ctx context.Context, q string, limit, offset int32) ([]*customer_onboarding.CustomerOnboardingModel, error) {
	rows, err := r.q.SearchCustomersByName(ctx, queries.SearchCustomersByNameParams{
		Column1: sql.NullString{String: q, Valid: true},
		Limit:   limit,
		Offset:  offset,
	})
	if err != nil {
		return nil, err
	}

	out := make([]*customer_onboarding.CustomerOnboardingModel, 0, len(rows))
	for _, row := range rows {
		out = append(out, toDomainFromSearchRow(row))
	}

	return out, nil
}

func (r *customerRepo) Delete(ctx context.Context, id int64) error {
	return r.q.DeleteCustomer(ctx, int32(id))
}

// package customer_onboarding_repo_impl

// import (
//     "context"
//     "database/sql"
//     "errors"
// 	"time"

//     // replace with your module path; typically module name from go.mod
//     queries "microfinpro/internal/db/queries/customer_onboarding"

//     "microfinpro/internal/domain/customer_onboarding"
// )

// type customerRepo struct {
//     q *queries.Queries
// }

// func NewCustomerRepo(db *sql.DB) customer_onboarding.Repository {
//     return &customerRepo{
//         q: queries.New(db),
//     }
// }

// func stringPtr(ns sql.NullString) *string {
// 	if ns.Valid {
// 		return &ns.String
// 	}
// 	return nil
// }

// func timePtr(nt sql.NullTime) *time.Time {
// 	if nt.Valid {
// 		return &nt.Time
// 	}
// 	return nil
// }

// func int64Ptr(ni sql.NullInt64) *int64 {
// 	if ni.Valid {
// 		return &ni.Int64
// 	}
// 	return nil
// }

// func nullString(ns *string) sql.NullString {
// 	if ns == nil {
// 		return sql.NullString{}
// 	}
// 	return sql.NullString{String: *ns, Valid: true}
// }

// func nullTime(t *time.Time) sql.NullTime {
// 	if t == nil {
// 		return sql.NullTime{}
// 	}
// 	return sql.NullTime{Time: *t, Valid: true}
// }

// func toDomainModel(m queries.Customer) *customer_onboarding.CustomerOnboardingModel {
// 	return &customer_onboarding.CustomerOnboardingModel{
// 		ID:             int64(m.ID), // cast int32 -> int64
// 		CustomerCode:   m.CustomerCode.String, // sql.NullString -> string
// 		FirstName:      m.FirstName,
// 		LastName:       m.LastName,
// 		DateOfBirth:    timePtr(m.DateOfBirth),
// 		Gender:         stringPtr(m.Gender),
// 		Email:          stringPtr(m.Email),
// 		PhoneNumber:    stringPtr(m.PhoneNumber),
// 		AadhaarNumber:  stringPtr(m.AadhaarNumber),
// 		PANNumber:      stringPtr(m.PanNumber),
// 		Address:        stringPtr(m.Address),
// 		City:           stringPtr(m.City),
// 		State:          stringPtr(m.State),
// 		Pincode:        stringPtr(m.Pincode),
// 		KYCStatus:      m.KycStatus.String,       // sql.NullString -> string
// 		CustomerStatus: m.CustomerStatus.String,  // sql.NullString -> string
// 		CreatedAt:      m.CreatedAt,
// 		UpdatedAt:      timePtr(m.UpdatedAt),
// 		DeletedAt:      timePtr(m.DeletedAt),
// 	}
// }

// func (r *customerRepo) Create(ctx context.Context, c *customer_onboarding.CustomerOnboardingModel) (*customer_onboarding.CustomerOnboardingModel, error) {
// 	arg := queries.CreateCustomerParams{
// 		FirstName:     c.FirstName,
// 		LastName:      c.LastName,
// 		DateOfBirth:   nullTime(c.DateOfBirth),
// 		Gender:        nullString(c.Gender),
// 		Email:         nullString(c.Email),
// 		PhoneNumber:   nullString(c.PhoneNumber),
// 		AadhaarNumber: nullString(c.AadhaarNumber),
// 		PanNumber:     nullString(c.PANNumber),
// 		Address:       nullString(c.Address),
// 		City:          nullString(c.City),
// 		State:         nullString(c.State),
// 		Pincode:       nullString(c.Pincode),
// 		KycStatus:     sql.NullString{String: c.KYCStatus, Valid: c.KYCStatus != ""},
// 		CustomerStatus: sql.NullString{String: c.CustomerStatus, Valid: c.CustomerStatus != ""},
// 	}

// 	res, err := r.q.CreateCustomer(ctx, arg)
// 	if err != nil {
// 		return nil, err
// 	}
// 	return toDomainModel(res), nil
// }

// func (r *customerRepo) GetByID(ctx context.Context, id int64) (*customer_onboarding.CustomerOnboardingModel, error) {
//     res, err := r.q.GetCustomerByID(ctx, id)
//     if err != nil {
//         if errors.Is(err, sql.ErrNoRows) {
//             return nil, nil
//         }
//         return nil, err
//     }
//     return toDomainModel(res), nil
// }

// func (r *customerRepo) GetByAadhaar(ctx context.Context, aadhaar string) (*customer_onboarding.CustomerOnboardingModel, error) {
//     res, err := r.q.GetCustomerByAadhaar(ctx, aadhaar)
//     if err != nil {
//         if errors.Is(err, sql.ErrNoRows) {
//             return nil, nil
//         }
//         return nil, err
//     }
//     return toDomainModel(res), nil
// }

// func (r *customerRepo) UpdateStatus(ctx context.Context, id int64, status string) error {
//     return r.q.UpdateCustomerStatus(ctx, queries.UpdateCustomerStatusParams{
//         ID: id, CustomerStatus: status,
//     })
// }

// func (r *customerRepo) UpdateKYCStatus(ctx context.Context, id int64, kyc string) error {
//     return r.q.UpdateCustomerKYCStatus(ctx, queries.UpdateCustomerKYCStatusParams{
//         ID: id, KycStatus: kyc,
//     })
// }

// func (r *customerRepo) ListActive(ctx context.Context, limit, offset int32) ([]*customer_onboarding.CustomerOnboardingModel, error) {
//     rows, err := r.q.ListActiveCustomers(ctx, queries.ListActiveCustomersParams{
//         Limit:  limit,
//         Offset: offset,
//     })
//     if err != nil {
//         return nil, err
//     }
//     out := make([]*customer_onboarding.CustomerOnboardingModel, 0, len(rows))
//     for _, rrow := range rows {
//         out = append(out, toDomainModel(rrow))
//     }
//     return out, nil
// }

// func (r *customerRepo) SearchByName(ctx context.Context, qstr string, limit, offset int32) ([]*customer_onboarding.CustomerOnboardingModel, error) {
//     rows, err := r.q.SearchCustomersByName(ctx, queries.SearchCustomersByNameParams{
//         Name:   qstr,
//         Limit:  limit,
//         Offset: offset,
//     })
//     if err != nil {
//         return nil, err
//     }
//     out := make([]*customer_onboarding.CustomerOnboardingModel, 0, len(rows))
//     for _, rrow := range rows {
//         out = append(out, toDomainModel(rrow))
//     }
//     return out, nil
// }

// func (r *customerRepo) Delete(ctx context.Context, id int64) error {
//     return r.q.DeleteCustomer(ctx, id)
// }
