defmodule Bookish.CheckOutTest do
  use Bookish.ModelCase

  alias Bookish.CheckOut
  alias Bookish.Book

  @valid_attrs %{checked_out_to: "A person", book_id: 1}
  @invalid_attrs %{}

  test "check-out is valid with checked_out_to and book_id" do
    changeset = CheckOut.changeset(%CheckOut{}, @valid_attrs)
    assert changeset.valid?
  end

  test "check-out is invalid with no attributes" do
    changeset = CheckOut.changeset(%CheckOut{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "current returns collection of current check_outs" do
    check_out = Repo.insert!(%CheckOut{})
    current_check_out = List.first(CheckOut.current(CheckOut) |> Repo.all)

    assert current_check_out == check_out
  end

  test "current returns an empty collection if no books are checked out" do
    {:ok, date} = Ecto.Date.cast(DateTime.utc_now())
    Repo.insert!(%CheckOut{return_date: date})
    assert empty? CheckOut.current(CheckOut) |> Repo.all 
  end

  test "current will return an entry for a single book that is checked out" do
    book = Repo.insert! %Book{}
    association =
      Ecto.build_assoc(book, :check_outs, checked_out_to: "Person")
    check_out = Repo.insert!(association)
    current_check_out = List.first(CheckOut.current(CheckOut, book.id) |> Repo.all)

    assert current_check_out == check_out
  end


  def empty?(coll) do
    is_nil(List.first(coll))
  end
end