defmodule Shoppinglist.Repo do
  use Ecto.Repo,
    otp_app: :shoppinglist,
    adapter: Ecto.Adapters.Postgres
end
