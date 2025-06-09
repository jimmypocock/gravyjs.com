import React, { useState, useRef } from 'react'
import GravyJS from 'gravyjs'
import 'gravyjs/dist/index.css'
import './App.css'

const sampleSnippets = [
  {
    title: 'Email Signature',
    content: `
      <p>Best regards,<br>
      [[name]]<br>
      [[title]]<br>
      [[company]]</p>
    `
  },
  {
    title: 'Meeting Reminder',
    content: '<p>Don\'t forget about our meeting at [[time]] on [[date]].</p>'
  },
  {
    title: 'Welcome Message',
    content: '<p>Welcome to [[company]], [[name]]! We\'re excited to have you on board.</p>'
  },
  {
    title: 'Thank You Note',
    content: '<p>Thank you for your business, [[name]]. We appreciate your support!</p>'
  }
];

function App() {
  const [content, setContent] = useState('');
  const [showOutput, setShowOutput] = useState(false);
  const [populatedContent, setPopulatedContent] = useState(null);
  const [variablePrefix, setVariablePrefix] = useState('[[');
  const [variableSuffix, setVariableSuffix] = useState(']]');
  const [useCustomPrompt, setUseCustomPrompt] = useState(false);
  const [showModal, setShowModal] = useState(false);
  const [modalData, setModalData] = useState(null);
  const editorRef = useRef(null);

  // Custom variable prompt function that shows a modal instead of browser prompt
  const customVariablePrompt = (variableName, prefix, suffix) => {
    return new Promise((resolve) => {
      setModalData({
        variableName,
        prefix,
        suffix,
        resolve
      });
      setShowModal(true);
    });
  };

  const handleModalSubmit = (value) => {
    if (modalData) {
      modalData.resolve(value);
      setModalData(null);
    }
    setShowModal(false);
  };

  const handleModalCancel = () => {
    if (modalData) {
      modalData.resolve(null);
      setModalData(null);
    }
    setShowModal(false);
  };

  const handlePopulateVariables = async () => {
    if (editorRef.current) {
      const result = await editorRef.current.populateVariables();

      if (result) {
        setPopulatedContent(result);
        setShowOutput(true);
      }
    }
  };

  const handleClearContent = () => {
    if (editorRef.current) {
      editorRef.current.setContent('');
    }
    setPopulatedContent(null);
    setShowOutput(false);
  };

  const handleInsertSample = () => {
    if (editorRef.current) {
      editorRef.current.setContent(`
        <p>Hello [[name]],</p>
        <p>This is a sample document with <strong>bold text</strong>, <em>italic text</em>, and <u>underlined text</u>.</p>
        <ul>
          <li>First bullet point</li>
          <li>Second bullet point</li>
        </ul>
        <ol>
          <li>First numbered item</li>
          <li>Second numbered item</li>
        </ol>
        <p>Visit our website: <a href="https://example.com">https://example.com</a></p>
        <p>Best regards,<br>[[company]]</p>
      `);
    }
  };

  const copyToClipboard = async (text, type = 'html') => {
    try {
      if (type === 'html' && populatedContent) {
        // Create a temporary div to hold the HTML content
        const tempDiv = document.createElement('div');
        tempDiv.innerHTML = populatedContent.html;

        // Copy both HTML and plain text to clipboard
        await navigator.clipboard.write([
          new ClipboardItem({
            'text/html': new Blob([populatedContent.html], { type: 'text/html' }),
            'text/plain': new Blob([populatedContent.plainText], { type: 'text/plain' })
          })
        ]);

        alert('Content copied to clipboard with formatting!');
      } else {
        // Fallback for plain text
        await navigator.clipboard.writeText(text);
        alert('Content copied to clipboard!');
      }
    } catch (error) {
      console.error('Failed to copy:', error);

      // Fallback method
      const tempTextarea = document.createElement('textarea');
      tempTextarea.value = text;
      document.body.appendChild(tempTextarea);
      tempTextarea.select();
      document.execCommand('copy');
      document.body.removeChild(tempTextarea);
      alert('Content copied to clipboard!');
    }
  };

  const handleVariableChange = () => {
    // Re-render the editor with new delimiters
    if (editorRef.current) {
      const currentContent = editorRef.current.getContent();
      editorRef.current.setContent(currentContent);
    }
  };

  return (
    <div className="App">
      <header className="App-header">
        <h1>GravyJS Demo</h1>
        <p>A WYSIWYG editor for React/NextJS applications with configurable variable templates</p>
      </header>

      <div className="demo-container">
        <div className="config-section">
          <h3>Configuration:</h3>
          <div className="config-inputs">
            <label>
              Variable Prefix:
              <input
                type="text"
                value={variablePrefix}
                onChange={(e) => {
                  setVariablePrefix(e.target.value);
                  handleVariableChange();
                }}
                className="config-input"
                maxLength="10"
              />
            </label>
            <label>
              Variable Suffix:
              <input
                type="text"
                value={variableSuffix}
                onChange={(e) => {
                  setVariableSuffix(e.target.value);
                  handleVariableChange();
                }}
                className="config-input"
                maxLength="10"
              />
            </label>
            <div className="example-text">
              Example: {variablePrefix}name{variableSuffix}
            </div>
            <label className="prompt-toggle">
              <input
                type="checkbox"
                checked={useCustomPrompt}
                onChange={(e) => setUseCustomPrompt(e.target.checked)}
              />
              Use Custom Modal Prompts (instead of browser prompts)
            </label>
          </div>
        </div>

        <div className="controls">
          <button onClick={handlePopulateVariables} className="control-btn populate-btn">
            🔄 Populate Variables
          </button>
          <button onClick={handleInsertSample} className="control-btn">
            📝 Insert Sample Template
          </button>
          <button onClick={handleClearContent} className="control-btn">
            🗑️ Clear Content
          </button>
          <button onClick={() => setShowOutput(!showOutput)} className="control-btn">
            {showOutput ? '👁️ Hide' : '👁️ Show'} Template View
          </button>
        </div>

        <div className="editor-container">
          <h3>Template Editor:</h3>
          <GravyJS
            ref={editorRef}
            initialValue={content}
            onChange={setContent}
            snippets={sampleSnippets}
            placeholder={`Create your template here... Use ${variablePrefix}${variableSuffix} button to insert variables`}
            className="demo-editor"
            variablePrefix={variablePrefix}
            variableSuffix={variableSuffix}
            onVariablePrompt={useCustomPrompt ? customVariablePrompt : undefined}
          />
        </div>

        {populatedContent && (
          <div className="output-container">
            <div className="output-header">
              <h3>Populated Content:</h3>
              <div className="copy-buttons">
                <button
                  onClick={() => copyToClipboard(populatedContent.html, 'html')}
                  className="copy-btn"
                >
                  📋 Copy with Formatting
                </button>
                <button
                  onClick={() => copyToClipboard(populatedContent.plainText)}
                  className="copy-btn"
                >
                  📄 Copy as Plain Text
                </button>
              </div>
            </div>
            <div className="populated-preview" dangerouslySetInnerHTML={{ __html: populatedContent.html }} />
          </div>
        )}

        {showOutput && (
          <div className="output-container">
            <h3>Template HTML:</h3>
            <pre className="html-output">{content}</pre>
          </div>
        )}

        {/* Custom Variable Modal */}
        {showModal && modalData && (
          <div className="modal-overlay" onClick={handleModalCancel}>
            <div className="modal-content" onClick={(e) => e.stopPropagation()}>
              <h3>Enter Variable Value</h3>
              <p>
                Please enter a value for variable: <strong>{modalData.variableName}</strong>
              </p>
              <p className="variable-example">
                This will replace: <code>{modalData.prefix}{modalData.variableName}{modalData.suffix}</code>
              </p>
              <input
                type="text"
                placeholder={`Enter value for ${modalData.variableName}...`}
                className="modal-input"
                autoFocus
                onKeyDown={(e) => {
                  if (e.key === 'Enter') {
                    handleModalSubmit(e.target.value);
                  } else if (e.key === 'Escape') {
                    handleModalCancel();
                  }
                }}
              />
              <div className="modal-buttons">
                <button
                  onClick={() => {
                    const input = document.querySelector('.modal-input');
                    handleModalSubmit(input.value);
                  }}
                  className="modal-btn modal-btn-primary"
                >
                  OK
                </button>
                <button onClick={handleModalCancel} className="modal-btn modal-btn-secondary">
                  Cancel
                </button>
              </div>
            </div>
          </div>
        )}

        <div className="instructions">
          <h3>How to Use Variable Templates:</h3>
          <ol>
            <li><strong>Configure Variables:</strong> Choose your preferred variable delimiters above (default: [[name]])</li>
            <li><strong>Choose Prompt Style:</strong> Toggle between browser prompts and custom modal prompts</li>
            <li><strong>Create Template:</strong> Type your content in the editor above</li>
            <li><strong>Insert Variables:</strong> Click the {variablePrefix}{variableSuffix} button to insert placeholders</li>
            <li><strong>Add Snippets:</strong> Use the 📝 button to insert pre-made snippets with variables</li>
            <li><strong>Populate Variables:</strong> Click "🔄 Populate Variables" and enter values for each variable</li>
            <li><strong>Copy & Use:</strong> Copy the populated content with formatting preserved for use in other applications</li>
          </ol>

          <div className="tip-box">
            <h4>💡 Pro Tips:</h4>
            <ul>
              <li>Use double brackets [[]] instead of curly braces to avoid conflicts with React/JSX</li>
              <li>You can customize variable delimiters - try %%, @@, or any other characters</li>
              <li>Toggle between browser prompts and custom modal prompts in the configuration section</li>
              <li>Custom modal prompts provide a better user experience and can be styled to match your application</li>
              <li>Your template stays unchanged - you can populate it multiple times with different values</li>
              <li>Formatting (bold, italic, lists, links) is preserved when copying</li>
              <li>Use meaningful variable names like [[firstName]], [[companyName]], [[meetingDate]]</li>
              <li>The "Copy with Formatting" button works best in modern applications that support rich text paste</li>
            </ul>
          </div>

          <div className="delimiter-examples">
            <h4>🔧 Popular Variable Delimiter Examples:</h4>
            <div className="delimiter-grid">
              <div className="delimiter-example">
                <strong>[[]]</strong> - Default (safe for React)
                <br />
                <code>[[name]]</code>
              </div>
              <div className="delimiter-example">
                <strong>%% %%</strong> - Percent signs
                <br />
                <code>%%name%%</code>
              </div>
              <div className="delimiter-example">
                <strong>@@ @@</strong> - At symbols
                <br />
                <code>@@name@@</code>
              </div>
              <div className="delimiter-example">
                <strong>&lt;&lt; &gt;&gt;</strong> - Angle brackets
                <br />
                <code>&lt;&lt;name&gt;&gt;</code>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

export default App