defmodule TaskTrackerWeb.TaskController do
  use TaskTrackerWeb, :controller

  alias TaskTracker.Tasks
  alias TaskTracker.Tasks.Task

  def index(conn, _params) do
    tasks = Tasks.list_tasks()
    render(conn, "index.html", tasks: tasks, header: "All Tasks")
  end

  def new(conn, _params) do
    changeset = Tasks.change_task(%Task{})
    render(conn, "new.html", changeset: changeset, task: nil)
  end

  def create(conn, %{"task" => task_params}) do
    case Tasks.create_task(task_params) do
      {:ok, task} ->
        conn
        |> put_flash(:info, "Task created successfully.")
        |> redirect(to: Routes.task_path(conn, :show, task))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset, task: nil)
    end
  end

  def show(conn, %{"id" => id}) do
    task = Tasks.get_task(id)
    user_id = get_session(conn, :user_id)
    task_cset = Tasks.change_task(task) #%Tasks.Task{user_id: user_id})
    render(conn, "show.html", task: task, user_id: user_id, changeset: task_cset)
  end

  def edit(conn, %{"id" => id}) do
    task = Tasks.get_task(id)
    changeset = Tasks.change_task(task)
    render(conn, "edit.html", task: task, changeset: changeset)
  end

  defp update(conn, task, task_params) do
    case Tasks.update_task(task, task_params) do
      {:ok, task} ->
        conn
        |> put_flash(:info, "Task updated successfully.")
        |> redirect(to: Routes.task_path(conn, :show, task))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", task: task, changeset: changeset)
    end
  end
  def update(conn, %{"id" => id, "task" => task_params}) do
    task = Tasks.get_task(id)
    changeset = Tasks.change_task(task)
    email = Map.get(task_params, "assign_user_email")
    task_params = Map.delete(task_params, "assign_user_email")
    
    user = TaskTracker.Users.get_user_by_email(email)
    cond do
      email == "" -> update(conn, task, Map.put(task_params, "user_id", nil))
      user -> update(conn, task, Map.put(task_params, "user_id", user.id))
      # invalid email
      true -> update(conn, task, Map.put(task_params, "user_id", -1))
    end
  end

  def delete(conn, %{"id" => id}) do
    task = Tasks.get_task!(id)
    {:ok, _task} = Tasks.delete_task(task)

    conn
    |> put_flash(:info, "Task deleted successfully.")
    |> redirect(to: Routes.task_path(conn, :index))
  end
end
