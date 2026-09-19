<?php

namespace App\Repositories;

interface TaskRepositoryInterface extends BaseRepositoryInterface
{
    public function findById(int|string $id);

    public function getByUserId(int|string $userId);
}
