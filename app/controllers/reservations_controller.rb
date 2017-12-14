class ReservationsController < ApplicationController
  before_action :require_login
  before_action :set_reservation, only: [:edit, :update, :destroy]

  def index
    @reservations = Reservation.users_reservations(current_user)
    Reservation.reservations_checkin_setter(@reservations)
    Reservation.reservations_checkout_setter(@reservations)
  end

  def create
    @reservation = Reservation.new(reservation_params)
    @reservation.checkin_date=(reservation_params[:checkin_date])
    @reservation.checkin_time=(reservation_params[:checkin_time])
    @reservation.checkout_date=(reservation_params[:checkout_date])
    @reservation.checkout_time=(reservation_params[:checkout_time])
    @reservation.convert_to_datetime
    @room_type = RoomType.find(params[:reservation][:room_type_id])
    result = @reservation.room_available?(@room_type)
    if result[0]
      if @reservation.save
        @reservation.decrease_room_inventory
        redirect_to reservations_path,{notice: "Your reservation " \
          "for the #{@reservation.room_name} has been made, $0 are due today"}
      else
        render :'room_types/show'
      end
    else
      redirect_to room_path(@reservation.room.hotel),
        {alert: "#{result[1]}"}
    end
  end

  def edit
    if @reservation.user_id == current_user.id
      Reservation.reservation_checkin_setter(@reservation)
      Reservation.reservation_checkout_setter(@reservation)
      render :edit
    else
      flash[:alert] = "You don't have permission to edit that reservation."
      redirect_to reservations_path
    end
  end

  def update
    @reservation.checkin_date=(reservation_params[:checkin_date])
    @reservation.checkin_time=(reservation_params[:checkin_time])
    @reservation.checkout_date=(reservation_params[:checkout_date])
    @reservation.checkout_time=(reservation_params[:checkout_time])
    @reservation.convert_to_datetime
    @reservation.number_of_rooms = reservation_params[:number_of_rooms]

    result =  @reservation.alter_room_inventory(
      params[:reservation][:orginal_number_of_rooms]
    )
    if !result || result[0]
      if @reservation.save
        redirect_to reservations_path,{notice: "Your reservation " \
          "for the #{@reservation.room_name} has been updated."}
        else
        render :edit
      end
    else
      redirect_to reservations_path, {alert: "#{result[1]}"}
    end
  end


  def destroy
    @reservation.increase_room_inventory
    @reservation.delete
    redirect_to reservations_path,{notice: "Your reservation for " \
      "#{@reservation.checkin_datetime.strftime('%A, %B %d, %Y')} has " \
      "been deleted."}
  end

  private
  def set_reservation
    @reservation = Reservation.find_by(id: params[:id])
  end


  def reservation_params
    params.require(:reservation).permit(
      :checkin_date,
      :checkin_time,
      :checkout_date,
      :checkout_time,
      :number_of_rooms,
      :room_id,
      :user_id
    )
  end
end
