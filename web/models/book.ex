defmodule Bookish.Book do
  use Bookish.Web, :model

  alias Bookish.CheckOut
  alias Bookish.Repo

  schema "books" do
    field :title, :string, virtual: true
    field :author_firstname, :string, virtual: true
    field :author_lastname, :string, virtual: true
    field :year, :integer, virtual: true
    field :current_location, :string
    field :checked_out, :boolean, virtual: true, default: false
    field :borrower_name, :string, virtual: true
    field :tags_list, :string, virtual: true

    belongs_to :book_metadata, Bookish.BookMetadata
    has_many :check_outs, Bookish.CheckOut
    belongs_to :location, Bookish.Location

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:title, :author_firstname, :author_lastname, :year, :book_metadata_id, :current_location, :tags_list, :location_id])
    |> validate_required([:location_id])
    |> validate_contains_book_metadata
  end

  def with_existing_metadata(struct, params \\ %{}) do
    struct
    |> cast(params, [:current_location, :location_id])
    |> validate_required([:location_id])
  end

  def checkout(struct, params \\ %{}) do
    struct
    |> cast(params, [:borrower_name, :checked_out, :current_location])
    |> validate_inclusion(:current_location, ["", nil])
  end

  def return(struct, params \\ %{}) do
    struct
    |> cast(params, [:current_location])
    |> validate_required([:current_location])
  end

  def set_virtual_attributes(struct, params \\ %{}) do
    struct
    |> cast(params, [:checked_out, :borrower_name, :title, :author_firstname, :author_lastname, :year])
  end

  def set_checked_out(struct, params \\ %{}) do
    struct
    |> cast(params, [:checked_out, :borrower_name])
  end

  # Helpers

  def checked_out?(book_id) when is_integer(book_id) do
    current_record_exists(book_id)
  end

  def checked_out?(book) do
    current_record_exists(book.id)
  end

  def borrower_name(book) do
    if checked_out?(book) do
      record = get_first_record(book.id)
      record.borrower_name
    end
  end

  def borrower_id(book) do
    if checked_out?(book) do
      record = get_first_record(book.id)
      record.borrower_id
    end
  end

  defp get_current_records(book_id) do
    CheckOut.current(CheckOut, book_id) |> Repo.all
  end

  def get_first_record(book_id) do
    get_current_records(book_id)
    |> List.first
  end

  def current_record_exists(book_id) do
    get_current_records(book_id)
    |> not_empty?
  end

  defp not_empty?(coll) do
    List.first(coll) != nil
  end

  # Validations

  defp validate_contains_book_metadata(changeset) do
    book_metadata_id = get_field(changeset, :book_metadata_id)
    validate_contains_book_metadata(changeset, book_metadata_id)
  end

  defp validate_contains_book_metadata(changeset, id) when is_nil(id) do
    changeset
    |> validate_required([:title, :author_firstname, :author_lastname, :year])
    |> add_error_if_all_fields_are_blank
  end

  defp validate_contains_book_metadata(changeset, _) do
    changeset
  end

  defp add_error_if_all_fields_are_blank(changeset) do
    if !get_field(changeset, :title) && !get_field(changeset, :author_firstname) && !get_field(changeset, :author_lastname) && !get_field(changeset, :year) do
      changeset
      |> add_error(:no_book_metadata, "You must choose a title or add new book data")
    else
      changeset
    end
  end

  # Queries

  def get_checked_out(query) do
    from b in query,
      join: c in CheckOut, on: c.book_id == b.id,
      where: is_nil(c.return_date),
      select: b
  end

  def get_checked_out(query, borrower_id) do
    from b in query,
      join: c in CheckOut, on: c.book_id == b.id,
      where: is_nil(c.return_date) and c.borrower_id == ^borrower_id,
      select: b
  end

  def get_books_with_metadata(metadata) do
    from b in Bookish.Book,
      join: d in Bookish.BookMetadata, on: b.book_metadata_id == d.id,
      where: d.id == ^metadata.id,
      select: b
  end

  def get_books_for_location_with_metadata(query, location, metadata) do
    from b in query,
      join: d in Bookish.BookMetadata, on: b.book_metadata_id == d.id,
      where: b.location_id == ^location.id,
      where: d.id == ^metadata.id,
      select: b
  end
end
