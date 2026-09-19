<?php
require __DIR__ . '/../vendor/autoload.php';
$app = require __DIR__ . '/../bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

try {
    \Illuminate\Support\Facades\Mail::raw('اختبار إرسال البريد من تطبيق Task-Management', function ($m) {
        $m->to('test@example.com')->subject('اختبار البريد');
    });
    echo "MAIL SENT\n";
} catch (\Throwable $e) {
    echo "MAIL ERROR: " . $e->getMessage() . "\n";
    echo $e->getTraceAsString();
}
