@extends('layouts.app')

@section('title', 'تحقق البريد الإلكتروني')

@section('content')
    <div class="mx-auto max-w-lg rounded-2xl border border-slate-200 bg-white p-8 shadow-sm">
        <h1 class="text-2xl font-bold text-slate-800">تحقق البريد الإلكتروني</h1>

        <p class="mt-4 text-sm text-slate-600">
            قبل المتابعة، يرجى التحقق من بريدك الإلكتروني من خلال الرابط الذي أرسلناه لك.
        </p>

        @if (session('status') == 'verification-link-sent')
            <div class="mt-4 rounded-xl border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-700">
                تم إرسال رابط التحقق مرة أخرى إلى بريدك الإلكتروني.
            </div>
        @endif

        <form method="POST" action="{{ route('verification.send') }}" class="mt-6">
            @csrf
            <button type="submit" class="w-full rounded-xl bg-indigo-600 px-4 py-3 font-semibold text-white hover:bg-indigo-500">
                إرسال رابط التحقق مرة أخرى
            </button>
        </form>
    </div>
@endsection
