<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\BoostRequest;
use App\Models\Mess;
use App\Models\SeatListing;
use App\Models\SponsorBanner;
use App\Models\User;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;

class AdminController extends Controller
{
    public function showLogin(): View|RedirectResponse
    {
        if (Auth::check() && Auth::user()->is_admin) {
            return redirect()->route('admin.dashboard');
        }

        return view('admin.login');
    }

    public function login(Request $request): RedirectResponse
    {
        $credentials = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        if (Auth::attempt($credentials, true)) {
            if (! Auth::user()->is_admin) {
                Auth::logout();

                return back()->withErrors(['email' => 'This account does not have company admin access.']);
            }
            $request->session()->regenerate();

            return redirect()->route('admin.dashboard');
        }

        return back()->withErrors(['email' => 'Invalid admin email or password.'])->onlyInput('email');
    }

    public function logout(Request $request): RedirectResponse
    {
        Auth::logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect()->route('admin.login');
    }

    public function dashboard(): View|RedirectResponse
    {
        if (! Auth::check() || ! Auth::user()->is_admin) {
            return redirect()->route('admin.login');
        }

        $stats = [
            'users' => User::where('is_admin', false)->count(),
            'messes' => Mess::count(),
            'active_listings' => SeatListing::where('status', 'active')->count(),
            'pending_boosts' => BoostRequest::where('status', 'pending')->count(),
            'boost_revenue' => (float) BoostRequest::where('status', 'approved')->sum('amount'),
            'active_banners' => SponsorBanner::where('is_active', true)->count(),
        ];

        $areaClusters = Mess::select('area', 'city', DB::raw('COUNT(*) as mess_count'))
            ->groupBy('area', 'city')
            ->orderByDesc('mess_count')
            ->get();

        $boostRequests = BoostRequest::with(['seatListing:id,title,area,monthly_rent', 'user:id,name,phone'])
            ->orderByRaw("CASE WHEN status = 'pending' THEN 0 ELSE 1 END")
            ->orderByDesc('created_at')
            ->limit(25)
            ->get();

        $banners = SponsorBanner::orderByDesc('id')->get();

        $listings = SeatListing::with(['poster:id,name,phone', 'mess:id,name'])
            ->orderByDesc('is_featured')
            ->orderByDesc('created_at')
            ->limit(30)
            ->get();

        $messes = Mess::withCount('activeMembers')
            ->with('creator:id,name,phone')
            ->orderByDesc('created_at')
            ->limit(30)
            ->get();

        return view('admin.dashboard', compact(
            'stats',
            'areaClusters',
            'boostRequests',
            'banners',
            'listings',
            'messes'
        ));
    }

    public function storeBanner(Request $request): RedirectResponse
    {
        abort_unless(Auth::check() && Auth::user()->is_admin, 403);

        $validated = $request->validate([
            'sponsor_name' => ['required', 'string', 'max:100'],
            'headline' => ['required', 'string', 'max:140'],
            'subtitle' => ['nullable', 'string', 'max:220'],
            'cta_label' => ['nullable', 'string', 'max:40'],
            'cta_value' => ['required', 'string', 'max:120'],
            'target_area' => ['nullable', 'string', 'max:80'],
        ]);

        SponsorBanner::create([
            ...$validated,
            'cta_label' => $validated['cta_label'] ?: 'Call Now',
            'target_area' => $validated['target_area'] ?: null,
            'is_active' => true,
        ]);

        return back()->with('status', 'Sponsor banner published to mobile app!');
    }

    public function toggleBanner(SponsorBanner $sponsorBanner): RedirectResponse
    {
        abort_unless(Auth::check() && Auth::user()->is_admin, 403);
        $sponsorBanner->update(['is_active' => ! $sponsorBanner->is_active]);

        return back()->with('status', 'Sponsor banner status updated.');
    }

    public function destroyBanner(SponsorBanner $sponsorBanner): RedirectResponse
    {
        abort_unless(Auth::check() && Auth::user()->is_admin, 403);
        $sponsorBanner->delete();

        return back()->with('status', 'Sponsor banner deleted.');
    }

    public function approveBoost(BoostRequest $boostRequest): RedirectResponse
    {
        abort_unless(Auth::check() && Auth::user()->is_admin, 403);

        DB::transaction(function () use ($boostRequest) {
            $boostRequest->update([
                'status' => 'approved',
                'reviewed_at' => now(),
            ]);

            $boostRequest->seatListing?->update([
                'is_featured' => true,
                'featured_until' => now()->addDays($boostRequest->duration_days),
            ]);
        });

        return back()->with('status', 'Boost approved! Listing is now Featured for 7 days.');
    }

    public function rejectBoost(BoostRequest $boostRequest): RedirectResponse
    {
        abort_unless(Auth::check() && Auth::user()->is_admin, 403);

        $boostRequest->update([
            'status' => 'rejected',
            'reviewed_at' => now(),
        ]);

        return back()->with('status', 'Boost request rejected.');
    }

    public function toggleFeaturedListing(SeatListing $seatListing): RedirectResponse
    {
        abort_unless(Auth::check() && Auth::user()->is_admin, 403);

        $seatListing->update([
            'is_featured' => ! $seatListing->is_featured,
            'featured_until' => ! $seatListing->is_featured ? now()->addDays(7) : null,
        ]);

        return back()->with('status', 'Listing featured status updated.');
    }

    public function destroyListing(SeatListing $seatListing): RedirectResponse
    {
        abort_unless(Auth::check() && Auth::user()->is_admin, 403);
        $seatListing->delete();

        return back()->with('status', 'Seat listing removed.');
    }
}
