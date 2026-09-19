<?php

namespace App\Livewire\Tasks;

use App\Models\Task;
use App\Notifications\TaskCreatedNotification;
use Livewire\Component;

class TaskBoard extends Component
{
    public string $search = '';

    public string $status = '';

    public string $priority = '';

    public string $title = '';

    public string $description = '';

    public string $taskStatus = 'Pending';

    public string $taskPriority = 'Medium';

    public function saveTask(): void
    {
        $this->validate([
            'title' => ['required', 'string', 'min:3', 'max:255'],
            'description' => ['nullable', 'string', 'max:1000'],
            'taskStatus' => ['required', 'in:Pending,In Progress,Completed'],
            'taskPriority' => ['required', 'in:Low,Medium,High'],
        ]);

        $task = auth()->user()->tasks()->create([
            'title' => $this->title,
            'description' => $this->description,
            'status' => $this->taskStatus,
            'priority' => $this->taskPriority,
        ]);

        auth()->user()->notify(new TaskCreatedNotification($task));

        $this->reset(['title', 'description', 'taskStatus', 'taskPriority']);
        $this->taskStatus = 'Pending';
        $this->taskPriority = 'Medium';

        session()->flash('success', 'تمت إضافة المهمة بنجاح، وتم إرسال إشعار إلى بريدك الإلكتروني.');
    }

    public function deleteTask(int $id): void
    {
        auth()->user()->tasks()->whereKey($id)->delete();

        session()->flash('success', 'تم حذف المهمة بنجاح.');
    }

    public function clearFilters(): void
    {
        $this->reset(['search', 'status', 'priority']);
    }

    public function render()
    {
        $tasks = auth()->user()->tasks()
            ->when($this->search !== '', function ($query) {
                $query->where(function ($q) {
                    $q->where('title', 'like', '%'.$this->search.'%')
                        ->orWhere('description', 'like', '%'.$this->search.'%');
                });
            })
            ->when($this->status !== '', function ($query) {
                $query->where('status', $this->status);
            })
            ->when($this->priority !== '', function ($query) {
                $query->where('priority', $this->priority);
            })
            ->latest()
            ->get();

        return view('livewire.tasks.task-board', [
            'tasks' => $tasks,
        ]);
    }
}
