<?php

namespace App\Repositories;

use App\Models\User;

class UserRepository extends BaseRepository implements UserRepositoryInterface
{
    public function __construct(User $model)
    {
        parent::__construct($model);
    }

    public function findByEmail(string $email): ?User
    {
        return $this->model->newQuery()
            ->whereRaw('LOWER(email) = ?', [mb_strtolower(trim($email))])
            ->first();
    }

    public function findByGoogleIdOrEmail(string $googleId, string $email): ?User
    {
        return $this->model->newQuery()
            ->where('google_id', $googleId)
            ->orWhereRaw('LOWER(email) = ?', [mb_strtolower(trim($email))])
            ->first();
    }
}
