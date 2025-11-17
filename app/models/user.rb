class User < ApplicationRecord
  belongs_to :teacher
  has_secure_password

  enum role: {
    guru: 'guru',
    waka_kurikulum: 'waka_kurikulum',
    kepala_sekolah: 'kepala_sekolah'
  }

  validates :email,
    presence: { message: "tidak boleh kosong" },
    format: {
      with: /\A(?!\d+\z)[^@\s]+@[^@\s]+\z/,
      message: 'harus berupa email yang valid'
    }

  validates :password,
    presence: { message: "tidak boleh kosong" },
    length: { minimum: 8, message: "minimal 8 karakter" },
    format: {
      with: /\A(?=.*[A-Z])(?=.*\d).+\z/,
      message: "harus mengandung huruf kapital dan angka"
    },
    if: :password_required?

  validates :password_confirmation,
    presence: { message: "tidak boleh kosong" },
    if: :password_required?

  validate :passwords_match, if: :password_required?

  def generate_password_reset_token!
    update_columns(
      reset_password_token: SecureRandom.urlsafe_base64,
      reset_password_sent_at: Time.current
    )
  end

  def password_token_valid?
    reset_password_sent_at > 2.hours.ago
  end

  def reset_password!(password, password_confirmation)
    update(
      password: password,
      password_confirmation: password_confirmation,
      reset_password_token: nil,
      reset_password_sent_at: nil
    )
  end

  private

  def passwords_match
    if password.present? && password_confirmation.present? && password != password_confirmation
      errors.delete(:password_confirmation) # buang error bawaan
      errors.add(:password_confirmation, "harus sama dengan kata sandi")
    end
  end

  def password_required?
    password.present? || new_record?
  end
end
