package database

import (
	"context"
	"time"

	"gorm.io/gorm"
)

type QueryBuilder struct {
	db    *gorm.DB
	ctx   context.Context
	table string
}

func NewQuery(ctx context.Context, db *gorm.DB) *QueryBuilder {
	return &QueryBuilder{db: db.WithContext(ctx), ctx: ctx}
}

func (q *QueryBuilder) Table(name string) *QueryBuilder {
	q.table = name
	return q
}

func (q *QueryBuilder) Paginate(page, pageSize int, result interface{}) (int64, error) {
	var total int64
	offset := (page - 1) * pageSize

	if err := q.db.Count(&total).Error; err != nil {
		return 0, err
	}

	if err := q.db.Offset(offset).Limit(pageSize).Find(result).Error; err != nil {
		return 0, err
	}

	return total, nil
}

func (q *QueryBuilder) PaginateWithSelect(page, pageSize int, query interface{}, args []interface{}, result interface{}) (int64, error) {
	var total int64

	// Count query
	countDB := q.db
	if query != nil {
		countDB = countDB.Where(query, args...)
	}
	if err := countDB.Count(&total).Error; err != nil {
		return 0, err
	}

	// Data query with offset
	offset := (page - 1) * pageSize
	dataDB := q.db
	if query != nil {
		dataDB = dataDB.Where(query, args...)
	}
	if err := dataDB.Offset(offset).Limit(pageSize).Find(result).Error; err != nil {
		return 0, err
	}

	return total, nil
}

func (q *QueryBuilder) RawCount(sql string, vars ...interface{}) (int64, error) {
	var total int64
	err := q.db.Raw(sql, vars...).Scan(&total).Error
	return total, err
}

func (q *QueryBuilder) WithPreload(fields ...string) *QueryBuilder {
	for _, field := range fields {
		q.db = q.db.Preload(field)
	}
	return q
}

func (q *QueryBuilder) WithSelect(fields ...string) *QueryBuilder {
	q.db = q.db.Select(fields)
	return q
}

func (q *QueryBuilder) WithFilters(filters map[string]interface{}) *QueryBuilder {
	for field, value := range filters {
		if value != nil && value != "" {
			q.db = q.db.Where(field, value)
		}
	}
	return q
}

func (q *QueryBuilder) WithILike(field, value string) *QueryBuilder {
	if value != "" {
		q.db = q.db.Where(field+" ILIKE ?", "%"+value+"%")
	}
	return q
}

func (q *QueryBuilder) WithDateRange(field string, from, to *time.Time) *QueryBuilder {
	if from != nil {
		q.db = q.db.Where(field+" >= ?", *from)
	}
	if to != nil {
		q.db = q.db.Where(field+" <= ?", *to)
	}
	return q
}

func (q *QueryBuilder) WithSort(sortBy, sortOrder string, allowedFields []string) *QueryBuilder {
	for _, f := range allowedFields {
		if f == sortBy {
			if sortOrder != "asc" && sortOrder != "desc" {
				sortOrder = "desc"
			}
			q.db = q.db.Order(sortBy + " " + sortOrder)
			return q
		}
	}
	q.db = q.db.Order("created_at DESC")
	return q
}

func (q *QueryBuilder) DB() *gorm.DB {
	return q.db
}

func (q *QueryBuilder) Clone() *QueryBuilder {
	return &QueryBuilder{
		db:  q.db.Session(&gorm.Session{}),
		ctx: q.ctx,
	}
}

type PerformanceHint struct {
	UseIndex        string
	AvoidJoin       bool
	PreloadFields   []string
	SelectFields    []string
	CacheTTL        time.Duration
	CursorPagination bool
}

func PerformancePreload(fields ...string) PerformanceHint {
	return PerformanceHint{PreloadFields: fields}
}

func PerformanceSelect(fields ...string) PerformanceHint {
	return PerformanceHint{SelectFields: fields}
}

type Cursor struct {
	AfterID  string
	BeforeID string
	Limit    int
}

func CursorPaginate(db *gorm.DB, table, sortField string, cursor Cursor, result interface{}) (int64, error) {
	query := db
	if cursor.AfterID != "" {
		query = query.Where(table+".id < ?", cursor.AfterID)
	}

	var total int64
	db.Model(result).Count(&total)

	if err := query.Order(sortField + " DESC").Limit(cursor.Limit).Find(result).Error; err != nil {
		return 0, err
	}

	return total, nil
}

func BatchInsert(db *gorm.DB, records []interface{}, batchSize int) error {
	if batchSize <= 0 {
		batchSize = 100
	}
	return db.CreateInBatches(records, batchSize).Error
}

func UpdateInBatches(db *gorm.DB, model interface{}, conditions map[string]interface{}, updates map[string]interface{}, batchSize int) *gorm.DB {
	query := db.Model(model)
	for k, v := range conditions {
		query = query.Where(k, v)
	}
	return query.Updates(updates)
}
