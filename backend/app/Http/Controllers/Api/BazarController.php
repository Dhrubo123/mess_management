<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\InteractsWithMess;
use App\Http\Controllers\Controller;
use App\Models\Bazar;
use App\Models\Mess;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class BazarController extends Controller
{
    use InteractsWithMess;

    public function index(Request $request, Mess $mess): JsonResponse
    {
        $this->requireMembership($request, $mess);
        $messMonth = $this->resolveMessMonth($request, $mess);

        $bazars = $messMonth->bazars()
            ->with('buyer:id,name,phone')
            ->orderByDesc('bazar_date')
            ->orderByDesc('id')
            ->get();

        return response()->json([
            'mess_month' => $messMonth,
            'total_amount' => round((float) $bazars->sum('amount'), 2),
            'bazars' => $bazars,
        ]);
    }

    public function store(Request $request, Mess $mess): JsonResponse
    {
        $this->requireMembership($request, $mess);

        $validated = $request->validate([
            'bought_by' => ['nullable', 'integer'],
            'bazar_date' => ['required', 'date'],
            'amount' => ['required', 'numeric', 'min:1'],
            'items_note' => ['nullable', 'string', 'max:1000'],
            'receipt' => ['nullable', 'image', 'max:4096'],
        ]);

        $bazarDate = \Carbon\Carbon::parse($validated['bazar_date']);
        $messMonth = $mess->months()->firstOrCreate(
            ['year' => (int) $bazarDate->year, 'month' => (int) $bazarDate->month],
            [
                'manager_id' => $mess->activeMembers()->where('role', 'manager')->value('user_id') ?? $mess->created_by,
                'status' => 'open',
            ]
        );
        $this->ensureMonthOpen($messMonth);

        $receiptPath = null;
        if ($request->hasFile('receipt')) {
            $receiptPath = $request->file('receipt')->store('bazar-receipts', 'public');
        }

        $bazar = Bazar::create([
            'mess_month_id' => $messMonth->id,
            'bought_by' => $validated['bought_by'] ?? $request->user()->id,
            'bazar_date' => $bazarDate->toDateString(),
            'amount' => $validated['amount'],
            'items_note' => $validated['items_note'] ?? null,
            'receipt_path' => $receiptPath,
            'created_by' => $request->user()->id,
        ]);

        return response()->json([
            'bazar' => $bazar->load('buyer:id,name,phone'),
        ], 201);
    }

    public function destroy(Request $request, Mess $mess, Bazar $bazar): JsonResponse
    {
        $this->requireManager($request, $mess);
        abort_if($bazar->messMonth->mess_id !== $mess->id, 404);
        $this->ensureMonthOpen($bazar->messMonth);

        $bazar->delete();

        return response()->json(['message' => 'Bazar entry deleted.']);
    }
}
