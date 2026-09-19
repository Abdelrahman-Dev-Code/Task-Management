<!DOCTYPE html>
<html lang="ar" dir="rtl">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>@yield('title', 'Task Management')</title>
        @if (file_exists(public_path('build/manifest.json')) || file_exists(public_path('hot')))
            @vite(['resources/css/app.css', 'resources/js/app.js'])
        @else
            <!-- Fallback: load Tailwind from CDN for quick styling when no build exists -->
            <script src="https://cdn.tailwindcss.com"></script>
            <script>
                tailwind.config = {
                    theme: {
                        extend: {
                            colors: {
                                indigo: {
                                    300: '#a5b4fc',
                                    400: '#818cf8',
                                    500: '#6366f1'
                                }
                            }
                        }
                    }
                };
            </script>
            <style>
                /* Small fallback styles and RTL fixes */
                html { direction: rtl; }
                body { font-family: Inter, ui-sans-serif, system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif; }
            </style>
        @endif
        @livewireStyles
    </head>
    <body class="bg-slate-50 text-slate-800 antialiased">
        <header class="border-b bg-white/50 backdrop-blur-sm">
            <div class="mx-auto max-w-7xl px-4 py-4 sm:px-6 lg:px-8">
                <nav class="flex items-center justify-between">
                    <a href="/" class="flex items-center gap-3">
                        <svg width="36" height="36" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="text-indigo-600"><rect width="24" height="24" rx="6" fill="currentColor"/></svg>
                        <span class="text-lg font-semibold text-slate-800">لوحة المهام</span>
                    </a>
                    <div class="hidden sm:flex items-center gap-4">
                        <a href="/tasks" class="text-sm font-medium text-slate-600 hover:text-slate-800">المهام</a>
                        <a href="/register" class="inline-flex items-center gap-2 rounded-full bg-indigo-600 px-4 py-2 text-sm font-semibold text-white hover:bg-indigo-500">إنشاء حساب</a>
                    </div>
                </nav>
            </div>
        </header>

        <main class="min-h-[calc(100vh-64px)]">
            <div class="mx-auto max-w-7xl px-4 py-12 sm:px-6 lg:px-8">
                @yield('content')
            </div>
        </main>

        <footer class="border-t bg-white/50 text-sm text-slate-500">
            <div class="mx-auto max-w-7xl px-4 py-4 sm:px-6 lg:px-8 text-center">© {{ date('Y') }} لوحة المهام — جميع الحقوق محفوظة</div>
        </footer>

        @livewireScripts
    </body>
</html>
