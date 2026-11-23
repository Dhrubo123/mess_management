<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('messes', function (Blueprint $table) {
            $table->json('facilities')->nullable()->after('has_breakfast');
            $table->string('food_mode', 20)->default('meal_rate')->after('facilities'); // meal_rate, fixed_food
        });
    }

    public function down(): void
    {
        Schema::table('messes', function (Blueprint $table) {
            $table->dropColumn(['facilities', 'food_mode']);
        });
    }
};
