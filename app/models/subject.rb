class Subject < ApplicationRecord
    validates :name, presence: {message: "mata pelajaran tidak boleh kosong"}
    validates :name, length: {minimum: 5, message: "miniman terdiri dari lima karakter"}, format: { with: /\A[a-zA-Z]+\z/,
    message: "harus berupa huruf" }
end
