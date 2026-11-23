<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class MessManagementApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_full_mess_management_and_to_let_flow(): void
    {
        // 1. Register manager
        $regManager = $this->postJson('/api/auth/register', [
            'name' => 'Tanvir',
            'phone' => '01700000001',
            'password' => 'secret123',
            'locale' => 'bn',
        ]);
        $regManager->assertCreated()->assertJsonStructure(['token', 'user']);
        $managerToken = $regManager->json('token');

        // 2. Register roommate
        $regRoommate = $this->postJson('/api/auth/register', [
            'name' => 'Rakib',
            'phone' => '01700000002',
            'password' => 'secret123',
        ]);
        $regRoommate->assertCreated();
        $roommateToken = $regRoommate->json('token');
        $roommateId = $regRoommate->json('user.id');

        // 3. Manager creates mess (enable breakfast for this test's breakfast+lunch+dinner math)
        $messRes = $this->withToken($managerToken)->postJson('/api/messes', [
            'name' => 'Mirpur Bachelor Mess',
            'area' => 'Mirpur 10',
            'has_breakfast' => true,
            'monthly_seat_rent' => 3000,
        ]);
        $messRes->assertCreated();
        $messId = $messRes->json('mess.id');
        $inviteCode = $messRes->json('mess.invite_code');

        // 4. Roommate joins using invite code
        $this->app->make('auth')->forgetGuards();
        $this->withToken($roommateToken)->postJson('/api/messes/join', [
            'invite_code' => $inviteCode,
            'monthly_seat_rent' => 3000,
        ])->assertOk();

        // 5. Log meals (Manager: 4 meals, Roommate: 6 meals => total 10 meals)
        $today = now()->toDateString();
        $this->app->make('auth')->forgetGuards();
        $this->withToken($managerToken)->postJson("/api/messes/{$messId}/meals", [
            'meal_date' => $today,
            'breakfast' => 1,
            'lunch' => 2,
            'dinner' => 1,
        ])->assertOk();

        $this->app->make('auth')->forgetGuards();
        $this->withToken($roommateToken)->postJson("/api/messes/{$messId}/meals", [
            'meal_date' => $today,
            'breakfast' => 2,
            'lunch' => 2,
            'dinner' => 2,
        ])->assertOk();

        // 6. Log bazar = ৳600 => meal rate should be 600 / 10 = ৳60
        $this->app->make('auth')->forgetGuards();
        $this->withToken($managerToken)->postJson("/api/messes/{$messId}/bazars", [
            'bazar_date' => $today,
            'amount' => 600,
            'items_note' => 'Rice and Chicken',
        ])->assertCreated();

        // 7. Log deposit for roommate = ৳1000
        $this->withToken($managerToken)->postJson("/api/messes/{$messId}/deposits", [
            'user_id' => $roommateId,
            'amount' => 1000,
            'deposit_type' => 'meal',
            'payment_method' => 'bkash',
            'deposit_date' => $today,
        ])->assertCreated();

        // 8. Log fixed bill = ৳1000 (split equally among 2 members => ৳500 each)
        $this->withToken($managerToken)->postJson("/api/messes/{$messId}/fixed-bills", [
            'title' => 'Wi-Fi',
            'category' => 'wifi',
            'total_amount' => 1000,
        ])->assertCreated();

        // 9. Verify monthly summary calculations
        $summary = $this->withToken($managerToken)->getJson("/api/messes/{$messId}/summary");
        $summary->assertOk()
            ->assertJsonPath('totals.total_meals', 10)
            ->assertJsonPath('totals.total_bazar', 600)
            ->assertJsonPath('totals.meal_rate', 60)
            ->assertJsonPath('totals.per_member_fixed_share', 500);

        // 10. Verify Bangla share text endpoint
        $share = $this->withToken($managerToken)->getJson("/api/messes/{$messId}/share-text?locale=bn");
        $share->assertOk()->assertSee('Mirpur Bachelor Mess');

        // 11. Handover manager role to roommate
        $this->withToken($managerToken)->postJson("/api/messes/{$messId}/handover", [
            'new_manager_user_id' => $roommateId,
        ])->assertOk();

        // 12. Post a Bachelor Seat / To-Let listing & browse publicly
        $this->app->make('auth')->forgetGuards();
        $listingRes = $this->withToken($roommateToken)->postJson('/api/seat-listings', [
            'mess_id' => $messId,
            'title' => '1 Seat Empty in Mirpur 10',
            'area' => 'Mirpur 10',
            'seat_type' => 'shared_seat',
            'monthly_rent' => 3500,
            'available_from' => now()->addDays(5)->toDateString(),
            'contact_phone' => '01700000002',
            'facilities' => ['Wi-Fi', 'Bua'],
        ]);
        $listingRes->assertCreated();

        $browse = $this->getJson('/api/seat-listings?area=Mirpur');
        $browse->assertOk()->assertJsonCount(1, 'listings');

        // 13. New manager (roommate) closes current month; edits should be blocked (422), then reopens it
        $this->app->make('auth')->forgetGuards();
        $this->withToken($roommateToken)->postJson("/api/messes/{$messId}/months/close", [
            'year' => now()->year,
            'month' => now()->month,
        ])->assertOk()->assertJsonPath('mess_month.status', 'closed');

        $this->withToken($roommateToken)->postJson("/api/messes/{$messId}/bazars", [
            'bazar_date' => $today,
            'amount' => 100,
        ])->assertStatus(422);

        $this->withToken($roommateToken)->postJson("/api/messes/{$messId}/months/reopen", [
            'year' => now()->year,
            'month' => now()->month,
        ])->assertOk()->assertJsonPath('mess_month.status', 'open');

        // 14. Upload Bazar receipt slip + Seat listing room photos
        Storage::fake('public');
        $bazarPhotoRes = $this->withToken($roommateToken)->post("/api/messes/{$messId}/bazars", [
            'bazar_date' => $today,
            'amount' => 450,
            'items_note' => 'Vegetables with slip',
            'receipt' => UploadedFile::fake()->image('slip.jpg'),
        ], ['Accept' => 'application/json']);
        $bazarPhotoRes->assertCreated();
        $this->assertNotNull($bazarPhotoRes->json('bazar.receipt_url'));

        $seatPhotoRes = $this->withToken($roommateToken)->post('/api/seat-listings', [
            'mess_id' => $messId,
            'title' => 'Chawk Bazar Room With Photos',
            'area' => 'Chawk Bazar',
            'seat_type' => 'shared_seat',
            'monthly_rent' => 3000,
            'available_from' => now()->addDays(5)->toDateString(),
            'contact_phone' => '01700000002',
            'facilities' => ['Wi-Fi', 'Bua'],
            'photos' => [
                UploadedFile::fake()->image('room1.jpg'),
                UploadedFile::fake()->image('room2.jpg'),
            ],
        ], ['Accept' => 'application/json']);
        $seatPhotoRes->assertCreated();
        $this->assertCount(2, $seatPhotoRes->json('listing.photo_urls'));

        // 15. Toggle mess to 2-meal mode (no breakfast) & test bulk manager meal entry
        $this->withToken($roommateToken)->patchJson("/api/messes/{$messId}/settings", [
            'has_breakfast' => false,
        ])->assertOk()->assertJsonPath('mess.has_breakfast', false);

        $this->withToken($roommateToken)->postJson("/api/messes/{$messId}/meals/bulk", [
            'meal_date' => $today,
            'entries' => [
                ['user_id' => $regManager->json('user.id'), 'lunch' => 1, 'dinner' => 1],
                ['user_id' => $roommateId, 'lunch' => 0, 'dinner' => 1],
            ],
        ])->assertOk()->assertJsonPath('count', 2);

        $this->withToken($roommateToken)->getJson("/api/messes/{$messId}/summary")
            ->assertOk()
            ->assertJsonPath('today_kitchen.lunch', 1)
            ->assertJsonPath('today_kitchen.dinner', 2);
    }
}
