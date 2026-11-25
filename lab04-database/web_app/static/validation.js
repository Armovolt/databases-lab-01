const bookForm = document.querySelector("[data-book-form]");
if (bookForm) {
  bookForm.addEventListener("submit", (event) => {
    const fields = bookForm.elements;
    const isbn = fields.isbn.value.trim();
    const year = Number(fields.published_year.value);
    const notification = bookForm.querySelector("[data-validation]");
    let message = "";
    let invalid = null;
    if (!fields.title.value.trim()) {
      message = "Вкажіть назву видання.";
      invalid = fields.title;
    } else if (!/^[0-9]{13}$/.test(isbn)) {
      message = "ISBN має складатися з 13 цифр.";
      invalid = fields.isbn;
    } else if (!fields.genre.value.trim()) {
      message = "Вкажіть жанр.";
      invalid = fields.genre;
    } else if (!Number.isInteger(year) || year < 1450 || year > 2100) {
      message = "Рік видання має бути від 1450 до 2100.";
      invalid = fields.published_year;
    }
    notification.textContent = message;
    notification.hidden = !message;
    if (invalid) {
      event.preventDefault();
      invalid.focus();
    }
  });
}
for (const form of document.querySelectorAll("[data-confirm]")) {
  form.addEventListener("submit", (event) => {
    if (!window.confirm("Видалити це видання з каталогу?")) {
      event.preventDefault();
    }
  });
}
