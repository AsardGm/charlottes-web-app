-- Migration: Add website and location fields to profiles table
-- This migration adds missing columns that are expected by the UserModel

ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS website TEXT,
ADD COLUMN IF NOT EXISTS location TEXT;
