<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SeatListing extends Model
{
    protected $fillable = [
        'mess_id',
        'posted_by',
        'title',
        'city',
        'area',
        'address_hint',
        'seat_type',
        'gender_preference',
        'seats_available',
        'monthly_rent',
        'avg_meal_cost',
        'available_from',
        'facilities',
        'photos',
        'contact_phone',
        'description',
        'is_featured',
        'featured_until',
        'status',
    ];

    protected $appends = ['photo_urls'];

    protected function casts(): array
    {
        return [
            'seats_available' => 'integer',
            'monthly_rent' => 'float',
            'avg_meal_cost' => 'float',
            'available_from' => 'date:Y-m-d',
            'facilities' => 'array',
            'photos' => 'array',
            'is_featured' => 'boolean',
            'featured_until' => 'datetime',
        ];
    }

    public function getPhotoUrlsAttribute(): array
    {
        $paths = is_array($this->photos) ? $this->photos : [];

        return array_values(array_map(
            fn ($p) => '/storage/' . ltrim((string) $p, '/'),
            $paths
        ));
    }

    public function mess(): BelongsTo
    {
        return $this->belongsTo(Mess::class);
    }

    public function poster(): BelongsTo
    {
        return $this->belongsTo(User::class, 'posted_by');
    }
}
