-- جدول المستخدمين
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  monthly_income REAL DEFAULT 6500,
  monthly_budget REAL DEFAULT 4800,
  currency TEXT DEFAULT 'ILS',
  created_at TIMESTAMP DEFAULT NOW()
);

-- جدول المعاملات
CREATE TABLE transactions (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  amount REAL NOT NULL,
  category TEXT NOT NULL,
  note TEXT,
  method TEXT DEFAULT 'يدوي',
  date TIMESTAMP DEFAULT NOW()
);

-- جدول الأهداف
CREATE TABLE goals (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  title TEXT NOT NULL,
  target_amount REAL NOT NULL,
  saved_amount REAL DEFAULT 0,
  emoji TEXT DEFAULT '🎯',
  deadline TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- جدول العائلة
CREATE TABLE family_members (
  id BIGSERIAL PRIMARY KEY,
  family_id TEXT NOT NULL,
  user_id UUID NOT NULL,
  role TEXT DEFAULT 'viewer',
  budget REAL DEFAULT 3000,
  joined_at TIMESTAMP DEFAULT NOW()
);

-- سياسات الأمان
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE goals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own data" ON users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own data" ON users FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can view own transactions" ON transactions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own transactions" ON transactions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can view own goals" ON goals FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own goals" ON goals FOR INSERT WITH CHECK (auth.uid() = user_id);