<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\InteractsWithMess;
use App\Http\Controllers\Controller;
use App\Models\Mess;
use App\Services\MessSummaryService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SummaryController extends Controller
{
    use InteractsWithMess;

    public function __construct(private readonly MessSummaryService $summaryService) {}

    public function monthly(Request $request, Mess $mess): JsonResponse
    {
        $membership = $this->requireMembership($request, $mess);
        $messMonth = $this->resolveMessMonth($request, $mess);

        $summary = $this->summaryService->calculate($mess, $messMonth);
        $summary['my_role'] = $membership->role;

        return response()->json($summary);
    }

    public function shareText(Request $request, Mess $mess): JsonResponse
    {
        $this->requireMembership($request, $mess);
        $messMonth = $this->resolveMessMonth($request, $mess);

        $locale = $request->query('locale', $request->user()->locale ?? 'en');
        $summary = $this->summaryService->calculate($mess, $messMonth);
        $text = $this->summaryService->buildShareText($summary, $locale);

        return response()->json([
            'locale' => $locale,
            'share_text' => $text,
        ]);
    }

    public function closeMonth(Request $request, Mess $mess): JsonResponse
    {
        $this->requireManager($request, $mess);
        $messMonth = $this->resolveMessMonth($request, $mess);

        $messMonth->update([
            'status' => 'closed',
            'closed_at' => now(),
        ]);

        return response()->json([
            'message' => 'Month closed and locked successfully.',
            'mess_month' => $messMonth->fresh(),
        ]);
    }

    public function reopenMonth(Request $request, Mess $mess): JsonResponse
    {
        $this->requireManager($request, $mess);
        $messMonth = $this->resolveMessMonth($request, $mess);

        $messMonth->update([
            'status' => 'open',
            'closed_at' => null,
        ]);

        return response()->json([
            'message' => 'Month reopened for edits.',
            'mess_month' => $messMonth->fresh(),
        ]);
    }
}
