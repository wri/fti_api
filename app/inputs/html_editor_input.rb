class HtmlEditorInput < Formtastic::Inputs::QuillEditorInput
  def input_html_options
    {
      data: {
        options: {
          modules: {
            toolbar: [['bold', 'italic', 'underline'],
                      ['link', 'video'],
                      [{ 'script': 'sub' }, { 'script': 'super' }],
                      [{ 'list': 'ordered' }, { 'list': 'bullet' }],
                      [{ 'color': [] }, { 'background': [] }],
                      ['clean']]
          },
          placeholder: 'Type something...',
          theme: 'snow'
        }
      }
    }.merge(super)
  end
end