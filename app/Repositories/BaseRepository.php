<?php

namespace App\Repositories;

abstract class BaseRepository implements BaseRepositoryInterface
{
    abstract protected function model(): string;

    public function all(array $columns = ['*'])
    {
        return $this->model()::query()->get($columns);
    }

    public function find(int|string $id, array $columns = ['*'])
    {
        return $this->model()::query()->find($id, $columns);
    }

    public function create(array $data)
    {
        return $this->model()::query()->create($data);
    }

    public function update(int|string $id, array $data)
    {
        $model = $this->find($id);

        if (! $model) {
            return null;
        }

        $model->update($data);

        return $model->fresh();
    }

    public function delete(int|string $id): bool
    {
        $model = $this->find($id);

        if (! $model) {
            return false;
        }

        return (bool) $model->delete();
    }
}
