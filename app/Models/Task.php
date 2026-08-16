<?php

namespace App\Models;

use Database\Factories\TaskFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;



#[Fillable(['Title','description','status','priority','user_id'])]
//#[Hidden(['password', 'remember_token'])]

class Task extends Model
{
    /** @use HasFactory<TaskFactory> */
    use HasFactory;

    protected $table = 'tasks';
    //protected $fillable = ['Title', 'description', 'status', 'priority', 'user_id'];

    /**
     * Description:
     *
     * @author Abdelrahman-Dev-Code
     * @created 2026-08-10
     * @modified 2026-08-10
     * @version 1
     * relation of user table 
     * @returns
     */
    public function users():BelongsTo{
        return $this->belongsTo(User::class, 'user_id', 'id');
    }
}
