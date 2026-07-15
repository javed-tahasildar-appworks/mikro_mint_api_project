package handler

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/go-chi/chi"

	"microfinpro/internal/domain/customer_onboarding"
	"microfinpro/internal/usecase/customer_onboarding"
)

type CustomerHandler struct {
	svc *customeronboardingusecase.Service
}

func NewCustomerHandler(svc *customeronboardingusecase.Service) *CustomerHandler {
	return &CustomerHandler{svc: svc}
}

func (h *CustomerHandler) Register(r chi.Router) {
	r.Post("/customers", h.createCustomer)
	r.Get("/customers/{id}", h.getCustomerByID)
	r.Put("/customers/{id}/status", h.updateStatus)
	// add other routes
}

type createReq struct {
	FirstName string `json:"first_name"`
	LastName  string `json:"last_name"`
	Email     string `json:"email"`
	// add other fields
}

func (h *CustomerHandler) createCustomer(w http.ResponseWriter, r *http.Request) {
	var req createReq
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid body", http.StatusBadRequest)
		return
	}

	// map to domain model
	c := &customer_onboarding.CustomerOnboardingModel{
		FirstName: req.FirstName,
		LastName:  req.LastName,
		Email:     &req.Email,
	}

	created, err := h.svc.CreateCustomer(r.Context(), c)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	_ = json.NewEncoder(w).Encode(created)
}

func (h *CustomerHandler) getCustomerByID(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		http.Error(w, "invalid id", http.StatusBadRequest)
		return
	}
	c, err := h.svc.GetCustomerByID(r.Context(), id)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	if c == nil {
		http.NotFound(w, r)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(c)
}

func (h *CustomerHandler) updateStatus(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, _ := strconv.ParseInt(idStr, 10, 64)
	var payload struct {
		Status string `json:"status"`
	}
	if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
		http.Error(w, "invalid body", http.StatusBadRequest)
		return
	}
	if err := h.svc.UpdateStatus(r.Context(), id, payload.Status); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
