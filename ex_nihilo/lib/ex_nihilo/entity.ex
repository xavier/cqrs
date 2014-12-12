defmodule ExNihilo.Entity do

  defmacro __using__(fields: fields) do

    fields = [{:uuid, nil} | fields]

    quote do

      defstruct unquote(fields)

      def get(uuid) do
        ExNihilo.DomainRepository.get(__MODULE__, uuid)
      end

      def new do
        %__MODULE__{}
      end

      def trigger(entity, event) do
        ExNihilo.DomainRepository.trigger(entity, event)
      end

    end
  end

end