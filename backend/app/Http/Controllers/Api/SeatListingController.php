<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\SeatListing;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SeatListingController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = SeatListing::query()
            ->with(['mess:id,name,area,is_pro', 'poster:id,name'])
            ->where('status', 'active');

        if ($request->filled('city')) {
            $query->where('city', $request->query('city'));
        }

        if ($request->filled('area')) {
            $area = $request->query('area');
            $query->where('area', 'like', "%{$area}%");
        }

        if ($request->filled('seat_type')) {
            $query->where('seat_type', $request->query('seat_type'));
        }

        if ($request->filled('gender')) {
            $query->where('gender_preference', $request->query('gender'));
        }

        if ($request->filled('max_rent')) {
            $query->where('monthly_rent', '<=', (float) $request->query('max_rent'));
        }

        $listings = $query
            ->orderByDesc('is_featured')
            ->orderByDesc('created_at')
            ->limit(50)
            ->get();

        return response()->json(['listings' => $listings]);
    }

    public function show(SeatListing $seatListing): JsonResponse
    {
        return response()->json([
            'listing' => $seatListing->load(['mess:id,name,area,city,is_pro', 'poster:id,name']),
        ]);
    }

    public function myListings(Request $request): JsonResponse
    {
        $listings = SeatListing::where('posted_by', $request->user()->id)
            ->with('mess:id,name,area')
            ->orderByDesc('created_at')
            ->get();

        return response()->json(['listings' => $listings]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'mess_id' => ['nullable', 'integer', 'exists:messes,id'],
            'title' => ['required', 'string', 'max:140'],
            'city' => ['nullable', 'string', 'max:60'],
            'area' => ['required', 'string', 'max:100'],
            'address_hint' => ['nullable', 'string', 'max:180'],
            'seat_type' => ['required', 'in:single_room,shared_seat,sublet'],
            'gender_preference' => ['nullable', 'in:male,female'],
            'seats_available' => ['nullable', 'integer', 'min:1', 'max:20'],
            'monthly_rent' => ['required', 'numeric', 'min:500'],
            'avg_meal_cost' => ['nullable', 'numeric', 'min:0'],
            'available_from' => ['required', 'date'],
            'facilities' => ['nullable', 'array'],
            'facilities.*' => ['string', 'max:40'],
            'photos' => ['nullable', 'array', 'max:4'],
            'photos.*' => ['image', 'max:4096'],
            'contact_phone' => ['required', 'string', 'max:20'],
            'description' => ['nullable', 'string', 'max:1500'],
        ]);

        $photoPaths = [];
        if ($request->hasFile('photos')) {
            foreach ($request->file('photos') as $file) {
                $photoPaths[] = $file->store('seat-photos', 'public');
            }
        }

        unset($validated['photos']);

        $listing = SeatListing::create([
            ...$validated,
            'city' => $validated['city'] ?? 'Chattogram',
            'gender_preference' => $validated['gender_preference'] ?? 'male',
            'seats_available' => $validated['seats_available'] ?? 1,
            'photos' => $photoPaths ?: null,
            'posted_by' => $request->user()->id,
            'status' => 'active',
        ]);

        return response()->json([
            'listing' => $listing->load(['mess:id,name,area', 'poster:id,name']),
        ], 201);
    }

    public function update(Request $request, SeatListing $seatListing): JsonResponse
    {
        abort_if($seatListing->posted_by !== $request->user()->id, 403, 'You can only update your own listing.');

        $validated = $request->validate([
            'title' => ['sometimes', 'string', 'max:140'],
            'monthly_rent' => ['sometimes', 'numeric', 'min:500'],
            'seats_available' => ['sometimes', 'integer', 'min:1', 'max:20'],
            'status' => ['sometimes', 'in:active,filled,archived'],
            'description' => ['nullable', 'string', 'max:1500'],
        ]);

        $seatListing->update($validated);

        return response()->json(['listing' => $seatListing->fresh()]);
    }

    public function destroy(Request $request, SeatListing $seatListing): JsonResponse
    {
        abort_if($seatListing->posted_by !== $request->user()->id, 403, 'You can only delete your own listing.');

        $seatListing->delete();

        return response()->json(['message' => 'Listing deleted.']);
    }
}
