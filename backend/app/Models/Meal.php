<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Meal extends Model
{
    protected $fillable = [
        'mess_month_id',
        'user_id',
        'meal_date',
        'breakfast',
        'lunch',
        'dinner',
        'guest_meals',
        'updated_by',
    ];

    protected function casts(): array
    {
        return [
            'meal_date' => 'date:Y-m-d',
            'breakfast' => 'float',
            'lunch' => 'float',
            'dinner' => 'float',
            'guest_meals' => 'float',
        ];
    }

    public function messMonth(): BelongsTo
    {
        return $this->belongsTo(MessMonth::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function totalForDay(): float
    {
        return (float) ($this->breakfast + $this->lunch + $this->dinner + $this->guest_meals);
    }
}
