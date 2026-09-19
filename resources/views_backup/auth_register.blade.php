@extends('layouts.app')

@section('title', 'إنشاء حساب')

@section('content')
    <div class="flex min-h-screen items-center justify-center bg-gradient-to-br from-slate-900 via-slate-800 to-indigo-900 p-4">
        <div class="w-full max-w-md rounded-2xl border border-white/10 bg-white/5 p-6 shadow-2xl backdrop-blur-md">
            <div class="mb-6 text-center">
                <h1 class="text-3xl font-bold text-white">إنشاء حساب جديد</h1>
                <p class="mt-2 text-sm text-slate-300">ابدأ بإدارة مهامك اليوم</p>
            </div>

            @livewire('auth.register-form')
        </div>
    </div>
@endsection
