<?php

namespace App\Http\Controllers\Api\Concerns;

use App\Models\Mess;
use App\Models\MessMember;
use App\Models\MessMonth;
use Illuminate\Http\Request;

trait InteractsWithMess
{
    protected function requireMembership(Request $request, Mess $mess): MessMember
    {
        $membership = $mess->activeMembers()
            ->where('user_id', $request->user()->id)
            ->first();

        abort_if(! $membership, 403, 'You are not an active member of this mess.');

        return $membership;
    }

    protected function requireManager(Request $request, Mess $mess): MessMember
    {
        $membership = $this->requireMembership($request, $mess);

        abort_if($membership->role !== 'manager', 403, 'Only the mess manager can perform this action.');

        return $membership;
    }

    protected function resolveMessMonth(Request $request, Mess $mess): MessMonth
    {
        $year = (int) ($request->query('year') ?? $request->input('year') ?? now()->year);
        $month = (int) ($request->query('month') ?? $request->input('month') ?? now()->month);

        $managerId = $mess->activeMembers()->where('role', 'manager')->value('user_id') ?? $mess->created_by;

        return $mess->months()->firstOrCreate(
            ['year' => $year, 'month' => $month],
            ['manager_id' => $managerId, 'status' => 'open']
        );
    }

    protected function ensureMonthOpen(MessMonth $messMonth): void
    {
        abort_if($messMonth->status === 'closed', 422, 'This month is closed and locked for edits.');
    }
}
