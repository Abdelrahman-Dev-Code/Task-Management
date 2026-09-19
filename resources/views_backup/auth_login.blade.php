@extends('layouts.app')

@section('title', 'تسجيل الدخول')

@section('content')
    <div class="flex min-h-[70vh] items-center justify-center">
        <div class="w-full max-w-6xl grid grid-cols-1 md:grid-cols-2 gap-8 items-center">
            <div class="hidden md:flex flex-col gap-6 rounded-2xl p-10 bg-gradient-to-br from-indigo-600 via-indigo-500 to-indigo-400 text-white shadow-xl">
                <div>
                    <h2 class="text-4xl font-extrabold">مرحباً بعودتك</h2>
                    <p class="mt-2 text-lg text-indigo-100/90">سجّل دخولك للوصول إلى لوحة التحكم وإدارة مهامك بسهولة.</p>
                </div>

                <ul class="mt-4 space-y-3 text-sm">
                    <li class="flex items-start gap-3"><span class="mt-1 inline-block h-2 w-2 rounded-full bg-white/90"></span>واجهة سريعة وسهلة الاستخدام</li>
                    <li class="flex items-start gap-3"><span class="mt-1 inline-block h-2 w-2 rounded-full bg-white/90"></span>حفظ تلقائي وتحديث فوري</li>
                    <li class="flex items-start gap-3"><span class="mt-1 inline-block h-2 w-2 rounded-full bg-white/90"></span>أمان قوي وحماية للبيانات</li>
                </ul>

                <div class="mt-auto text-sm text-indigo-50/80">لوحة المهام — إدارة يومية أفضل</div>
            </div>

            <div class="flex items-center justify-center">
                <div class="w-full max-w-md rounded-2xl bg-white p-8 shadow-lg">
                    <div class="mb-6 text-center">
                        <h1 class="text-2xl font-bold text-slate-800">تسجيل الدخول</h1>
                        <p class="mt-2 text-sm text-slate-500">استخدم حسابك للوصول إلى لوحة التحكم</p>
                    </div>

                    @livewire('auth.login-form')
                </div>
            </div>
        </div>
    </div>
@endsection
