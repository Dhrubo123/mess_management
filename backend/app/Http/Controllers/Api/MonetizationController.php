<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\BoostRequest;
use App\Models\SeatListing;
use App\Models\SponsorBanner;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MonetizationController extends Controller
{
    public function banners(Request $request): JsonResponse
    {
        $area = trim((string) $request->query('area', ''));

        $query = SponsorBanner::where('is_active', true);

        if ($area !== '' && $area !== 'All') {
            $query->where(function ($q) use ($area) {
                $q->whereNull('target_area')
                    ->orWhere('target_area', '')
                    ->orWhere('target_area', 'like', "%{$area}%");
            });
        }

        return response()->json([
            'banners' => $query->orderByDesc('id')->limit(5)->get(),
        ]);
    }

    public function requestBoost(Request $request, SeatListing $seatListing): JsonResponse
    {
        abort_if($seatListing->posted_by !== $request->user()->id, 403, 'You can only boost your own seat listing.');

        $validated = $request->validate([
            'payment_method' => ['required', 'in:bkash,nagad'],
            'sender_phone' => ['required', 'string', 'max:20'],
            'trx_id' => ['required', 'string', 'max:60'],
        ]);

        $boost = BoostRequest::create([
            'seat_listing_id' => $seatListing->id,
            'user_id' => $request->user()->id,
            'amount' => 99,
            'payment_method' => $validated['payment_method'],
            'sender_phone' => $validated['sender_phone'],
            'trx_id' => strtoupper(trim($validated['trx_id'])),
            'duration_days' => 7,
            'status' => 'pending',
        ]);

        return response()->json([
            'message' => 'Boost request submitted! Our CTG team will verify your TrxID shortly.',
            'boost_request' => $boost,
        ], 201);
    }
}
