<?php

namespace App\Http\Controllers;

use App\Http\Resources\NotificationResource;
use App\Models\AppNotification;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $notifications = AppNotification::query()
            ->where('user_id', $request->user()->id)
            ->latest('id')
            ->get();

        $unreadCount = $notifications->whereNull('read_at')->count();

        return response()->json([
            'data' => NotificationResource::collection($notifications)->resolve($request),
            'unread_count' => $unreadCount,
            'message' => 'تم جلب الإشعارات بنجاح.',
        ]);
    }

    public function markAsRead(Request $request, int $id): JsonResponse
    {
        $notification = AppNotification::query()
            ->where('user_id', $request->user()->id)
            ->where('id', $id)
            ->first();

        if (! $notification) {
            return response()->json(['message' => 'الإشعار غير موجود.'], 404);
        }

        if (! $notification->read_at) {
            $notification->forceFill(['read_at' => now()])->save();
            $notification->refresh();
        }

        return response()->json([
            'data' => (new NotificationResource($notification))->resolve($request),
            'message' => 'تم تحديد الإشعار كمقروء.',
        ]);
    }

    public function markAllRead(Request $request): JsonResponse
    {
        $updatedCount = AppNotification::query()
            ->where('user_id', $request->user()->id)
            ->whereNull('read_at')
            ->update(['read_at' => now()]);

        return response()->json([
            'updated_count' => $updatedCount,
            'message' => 'تم تحديد جميع الإشعارات كمقروءة.',
        ]);
    }
}
