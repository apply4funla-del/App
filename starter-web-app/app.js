const STORAGE_KEY = "starter-web-app.tasks";

const taskForm = document.querySelector("#task-form");
const taskInput = document.querySelector("#task-input");
const taskList = document.querySelector("#task-list");
const progressLabel = document.querySelector("#progress-label");
const taskTemplate = document.querySelector("#task-template");
const filterButtons = document.querySelectorAll(".filter-button");

let tasks = loadTasks();
let activeFilter = "all";

render();

taskForm.addEventListener("submit", (event) => {
  event.preventDefault();

  const title = taskInput.value.trim();
  if (!title) {
    return;
  }

  tasks.unshift({
    id: crypto.randomUUID(),
    title,
    done: false,
  });

  persistTasks();
  taskInput.value = "";
  taskInput.focus();
  render();
});

filterButtons.forEach((button) => {
  button.addEventListener("click", () => {
    activeFilter = button.dataset.filter;

    filterButtons.forEach((item) => {
      item.classList.toggle("is-active", item === button);
    });

    render();
  });
});

function render() {
  const visibleTasks = tasks.filter((task) => {
    if (activeFilter === "open") {
      return !task.done;
    }

    if (activeFilter === "done") {
      return task.done;
    }

    return true;
  });

  taskList.innerHTML = "";

  visibleTasks.forEach((task) => {
    const taskNode = taskTemplate.content.firstElementChild.cloneNode(true);
    const checkbox = taskNode.querySelector('input[type="checkbox"]');
    const title = taskNode.querySelector(".task-title");
    const deleteButton = taskNode.querySelector(".delete-button");

    checkbox.checked = task.done;
    title.textContent = task.title;
    taskNode.classList.toggle("is-done", task.done);

    checkbox.addEventListener("change", () => {
      toggleTask(task.id);
    });

    deleteButton.addEventListener("click", () => {
      deleteTask(task.id);
    });

    taskList.append(taskNode);
  });

  const doneCount = tasks.filter((task) => task.done).length;
  progressLabel.textContent = `${doneCount} of ${tasks.length} complete`;
}

function toggleTask(taskId) {
  tasks = tasks.map((task) =>
    task.id === taskId ? { ...task, done: !task.done } : task,
  );

  persistTasks();
  render();
}

function deleteTask(taskId) {
  tasks = tasks.filter((task) => task.id !== taskId);
  persistTasks();
  render();
}

function loadTasks() {
  try {
    const savedTasks = localStorage.getItem(STORAGE_KEY);
    return savedTasks ? JSON.parse(savedTasks) : [];
  } catch {
    return [];
  }
}

function persistTasks() {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(tasks));
}
