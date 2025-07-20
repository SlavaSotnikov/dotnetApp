  CREATE DATABASE Products;
  GO

  USE Products;
  GO

  CREATE TABLE Products (Id INT IDENTITY PRIMARY KEY, Name NVARCHAR(100), Price DECIMAL(10,2));
  GO

  INSERT INTO Products (Name, Price) VALUES
  ('Sugar', 32.0),
  ('Salt', 19.0),
  ('Bread', 20.0),
  ('Butter', 62.0),
  ('Milk', 32.0);
