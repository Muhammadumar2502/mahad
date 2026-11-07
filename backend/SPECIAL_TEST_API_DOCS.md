# Special Test API Documentation

## Overview
The Special Test API allows admins to create, manage, and assign special tests to student groups with time-based activation periods.

## Authentication
All endpoints require JWT authentication. Include the token in the Authorization header:
```
Authorization: Bearer <your-jwt-token>
```

## Endpoints

### 1. Create Special Test
**POST** `/special-test`

**Access:** Admin only

**Request Body:**
```json
{
  "name": "Matematika fanidan maxsus test",
  "description": "1-sinf o'quvchilari uchun maxsus matematika testi",
  "subject_id": 1,
  "book_id": 2,
  "section_id": 3,
  "group_ids": [1, 2, 3],
  "activation_start": "2025-11-15T08:00:00Z",
  "activation_end": "2025-11-20T22:00:00Z",
  "time_per_question": 60,
  "total_time": 3600,
  "question_count": 10,
  "questions": [
    {
      "number": 1,
      "question": "2 + 3 = ?",
      "answer_A": "4",
      "answer_B": "5",
      "answer_C": "6",
      "answer_D": "7",
      "answer": "B"
    }
  ]
}
```

**Response (201):**
```json
{
  "id": 1,
  "name": "Matematika fanidan maxsus test",
  "description": "1-sinf o'quvchilari uchun maxsus matematika testi",
  "subject_id": 1,
  "book_id": 2,
  "section_id": 3,
  "activation_start": "2025-11-15T08:00:00.000Z",
  "activation_end": "2025-11-20T22:00:00.000Z",
  "time_per_question": 60,
  "total_time": 3600,
  "question_count": 10,
  "createdAt": "2025-11-15T10:00:00.000Z",
  "updatedAt": "2025-11-15T10:00:00.000Z",
  "questions": [
    {
      "id": 1,
      "number": 1,
      "question": "2 + 3 = ?",
      "answer_A": "4",
      "answer_B": "5",
      "answer_C": "6",
      "answer_D": "7",
      "answer": "B",
      "specialTestId": 1
    }
  ],
  "specialTestGroups": [
    {
      "id": 1,
      "specialTestId": 1,
      "groupId": 1,
      "group": {
        "id": 1,
        "name": "1-sinf A"
      }
    }
  ]
}
```

**Error Responses:**
- `403 Forbidden`: User is not admin
- `404 Not Found`: Subject/Book/Section/Group not found
- `400 Bad Request`: Invalid data format

### 2. Get All Special Tests
**GET** `/special-test/all`

**Access:** Admin (all tests), Student (only assigned active tests)

**Response (200):**
```json
[
  {
    "id": 1,
    "name": "Matematika fanidan maxsus test",
    "description": "1-sinf o'quvchilari uchun maxsus matematika testi",
    "subject_id": 1,
    "book_id": 2,
    "section_id": 3,
    "activation_start": "2025-11-15T08:00:00.000Z",
    "activation_end": "2025-11-20T22:00:00.000Z",
    "time_per_question": 60,
    "total_time": 3600,
    "question_count": 10,
    "createdAt": "2025-11-15T10:00:00.000Z",
    "updatedAt": "2025-11-15T10:00:00.000Z",
    "questions": [...],
    "specialTestGroups": [...]
  }
]
```

### 3. Get Special Test by ID
**GET** `/special-test/:id`

**Access:** Admin (any test), Student (only assigned active tests)

**Response (200):** Same as create response

**Error Responses:**
- `404 Not Found`: Test not found
- `403 Forbidden`: Student doesn't have access to this test

### 4. Update Special Test
**PATCH** `/special-test/:id`

**Access:** Admin only

**Request Body:** Same as create, but all fields are optional

**Response (200):** Updated test object

### 5. Delete Special Test
**DELETE** `/special-test/:id`

**Access:** Admin only

**Response (200):**
```json
{
  "message": "Special test deleted successfully"
}
```

## Field Descriptions

### Test Fields
- `name`: Test nomi (required, string)
- `description`: Test tavsifi (optional, string)
- `subject_id`: Fan ID (required, number)
- `book_id`: Kitob ID (required, number)
- `section_id`: Bo'lim ID (required, number)
- `group_ids`: Guruhlar ID lari massivi (required, number[])
- `activation_start`: Test boshlanish vaqti (required, ISO string)
- `activation_end`: Test tugash vaqti (required, ISO string)
- `time_per_question`: Har bir savol uchun vaqt (sekundda, required, number)
- `total_time`: Umumiy vaqt (sekundda, required, number)
- `question_count`: Savollar soni (required, number)

### Question Fields
- `number`: Savol raqami (required, number, min: 1)
- `question`: Savol matni (required, string)
- `answer_A`: A varianti (required, string)
- `answer_B`: B varianti (required, string)
- `answer_C`: C varianti (optional, string)
- `answer_D`: D varianti (optional, string)
- `answer`: To'g'ri javob (required, "A"|"B"|"C"|"D")

## Important Notes

1. **Time Format**: Use ISO 8601 format for dates (e.g., "2025-11-15T08:00:00Z")
2. **Group Assignment**: Tests are assigned to multiple groups via `group_ids` array
3. **Activation Period**: Students can only see tests during the activation period
4. **Question Ordering**: Questions are ordered by `number` field in responses
5. **Validation**: All required fields are validated on both frontend and backend
6. **Role-based Access**: Students only see tests assigned to their group and within active periods

## Frontend Integration Example

```javascript
// Create special test
const createTest = async (testData) => {
  const response = await fetch('/special-test', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    },
    body: JSON.stringify(testData)
  });

  if (response.ok) {
    const test = await response.json();
    console.log('Test created:', test);
  }
};

// Get all tests for current user
const getTests = async () => {
  const response = await fetch('/special-test/all', {
    headers: {
      'Authorization': `Bearer ${token}`
    }
  });

  if (response.ok) {
    const tests = await response.json();
    console.log('Tests:', tests);
  }
};
```