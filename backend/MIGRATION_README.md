# Manual Migration Instructions

## Problem
Prisma shadow database error when running migrations on production server.

## Solution
Run the SQL script directly on your production database.

## Steps

### Option 1: Using MySQL Command Line
```bash
mysql -u your_username -p mahad_test_db < manual_migration.sql
```

### Option 2: Using phpMyAdmin or MySQL Workbench
1. Open phpMyAdmin or MySQL Workbench
2. Select the `mahad_test_db` database
3. Open the SQL tab
4. Copy and paste the contents of `manual_migration.sql`
5. Execute the script

### Option 3: Using SSH on Server
```bash
# SSH into your server
ssh user@your-server

# Navigate to backend directory
cd /home/book/Mahad-backend

# Run the migration
mysql -u root -p mahad_test_db < manual_migration.sql
```

## What This Migration Does
Adds three new columns to the `Book` table:
- `fullBlock` (BOOLEAN, default: false) - Controls if the entire book is blocked
- `stepBlock` (BOOLEAN, default: false) - Controls step-by-step section unlocking
- `passingPercentage` (INT, default: 60) - Minimum percentage required to pass sections

## Verification
After running the migration, verify the columns exist:
```sql
DESCRIBE Book;
```

You should see:
- fullBlock
- stepBlock
- passingPercentage

## Troubleshooting
If you get "column already exists" error, that's fine - the script checks for existing columns before adding them.
